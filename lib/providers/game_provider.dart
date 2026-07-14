import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/constants/difficulty.dart';
import '../data/repositories/records_repository.dart';
import '../data/repositories/savegame_repository.dart';
import '../domain/engine/board_generator.dart';
import '../domain/engine/liar_engine.dart';
import '../domain/engine/minesweeper_engine.dart';
import '../domain/engine/scoring.dart';
import '../domain/engine/tower_engine.dart';
import '../domain/engine/waves_engine.dart';
import '../domain/models/board.dart';
import '../domain/models/cell.dart';
import '../domain/models/game_config.dart';
import '../domain/models/game_mode.dart';
import '../domain/models/game_outcome.dart';
import '../domain/models/game_status.dart';
import '../domain/models/tower.dart';
import '../domain/models/wave_modifier.dart';

/// Estado de la partida actual (plan §6.3). **No contiene lógica de juego**:
/// orquesta los engines (Dart puro) ↔ la UI y notifica cambios. Se crea scoped a
/// `GameScreen` con `ChangeNotifierProvider` y se destruye al salir.
///
/// Soporta el modo Clásico (§2.1) y Contrarreloj/Blitz (§2.3). Blitz añade
/// cronómetro descendente, regeneración de tablero y puntaje con combos
/// (delegado en [BlitzScoring]).
class GameProvider extends ChangeNotifier {
  GameProvider({
    required this.config,
    required this.difficulty,
    required RecordsRepository records,
    SavegameRepository? savegame,
    bool resumeWaves = false,
    bool invertControls = false,
    bool isDaily = false,
    int bonusFlashlight = 0,
    int bonusFreezer = 0,
    int bonusScanner = 0,
    void Function(GameOutcome outcome)? onGameEnd,
    WaveModifier? debugForceModifier,
    BoardGenerator generator = const BoardGenerator(),
    MinesweeperEngine engine = const MinesweeperEngine(),
  })  : _records = records,
        _savegameRepo = savegame,
        _invertControls = invertControls,
        _isDaily = isDaily,
        _bonusFlashlight = bonusFlashlight,
        _bonusFreezer = bonusFreezer,
        _bonusScanner = bonusScanner,
        _onGameEnd = onGameEnd,
        _debugForceModifier = debugForceModifier,
        _generator = generator,
        _engine = engine {
    if (isWaves) {
      _startWavesRun(resume: resumeWaves);
    } else if (isTower) {
      _startTower();
    } else {
      _startNewBoard();
    }
  }

  // Nota: se usa lista de inicialización (no initializing formals) a propósito,
  // para exponer nombres públicos de parámetros (records/generator/engine)
  // manteniendo los campos privados.
  // ignore_for_file: prefer_initializing_formals

  final GameConfig config;
  final Difficulty difficulty;

  final RecordsRepository _records;
  final SavegameRepository? _savegameRepo;
  final BoardGenerator _generator;
  final MinesweeperEngine _engine;
  final bool _invertControls;

  /// La partida es un Reto Diario (plan §2.7): afecta a las monedas/racha.
  final bool _isDaily;

  /// Cargas iniciales extra provenientes de consumibles de la tienda (§3.1).
  final int _bonusFlashlight;
  final int _bonusFreezer;
  final int _bonusScanner;

  /// Se invoca al terminar la partida con la instantánea del resultado, para
  /// que la capa de UI otorgue monedas/logros (economía, Fase 5).
  final void Function(GameOutcome outcome)? _onGameEnd;

  /// `true` si el jugador puso al menos una bandera (logro "sin banderas").
  bool _usedAnyFlag = false;

  /// Fuerza un modificador de oleada (solo tests); si es `null`, se sortea.
  final WaveModifier? _debugForceModifier;

  // ── Constantes de Blitz (plan §2.3) ────────────────────────────────
  static const _blitzBudgetMs = 60000; // 60s iniciales
  static const _blitzBoardBonusMs = 20000; // +20s por tablero
  static const _freezerBonusMs = 10000; // Congelador: +10s

  static const _flashlightMs = 5000; // Linterna: ilumina 5s (§2.2)

  bool get isBlitz => config.mode == GameMode.blitz;
  bool get isFog => config.mode == GameMode.fog;
  bool get isLiar => config.mode == GameMode.liar;
  bool get isWaves => config.mode == GameMode.waves;
  bool get isTower => config.mode == GameMode.tower;
  bool get isClassicScored => config.mode == GameMode.classic;

  static const _liarEngine = LiarEngine();
  static const _wavesEngine = WavesEngine();
  static const _towerEngine = TowerEngine();
  final Random _wavesRng = Random();

  // ── Torre 3D (plan §2.6) ───────────────────────────────────────────
  Tower? _tower;
  Tower? get tower => _tower;

  /// Capa activa contada desde arriba (1 = cima), para el HUD.
  int get towerLayer => _tower?.displayLayer ?? 1;
  int get towerLayerCount => _tower?.layerCount ?? config.layers;

  // ── Estado observable ──────────────────────────────────────────────
  late Board _board;
  Board get board => _board;

  GameStatus _status = GameStatus.idle;
  GameStatus get status => _status;

  bool _flagMode = false;
  bool get flagMode => _flagMode;

  bool _minesPlaced = false;

  /// Cronómetro en su propio notificador → el HUD del tiempo se reconstruye
  /// solo, sin repintar el tablero (plan §6.3 regla 4). En Clásico cuenta hacia
  /// arriba (tiempo transcurrido); en Blitz hacia abajo (tiempo restante).
  final ValueNotifier<Duration> elapsed = ValueNotifier(Duration.zero);
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;

  // ── Blitz ──────────────────────────────────────────────────────────
  final BlitzScoring _scoring = BlitzScoring();
  int _timeBudgetMs = _blitzBudgetMs;
  int _freezerCharges = 1;
  bool _timeUp = false;

  int get blitzScore => _scoring.score;
  int get blitzBoards => _scoring.boardsSolved;
  int get comboMultiplier => _scoring.multiplier;
  double get comboProgress => _scoring.comboProgress;
  int get freezerCharges => _freezerCharges;
  bool get timeUp => _timeUp;

  // ── Niebla (plan §2.2) ─────────────────────────────────────────────
  // El foco es la última celda tocada; el brillo de cada celda lo calcula el
  // FogEngine (puro) en el BoardWidget usando estos datos + el reloj de pared.
  int _fogFocusRow = -1;
  int _fogFocusCol = -1;
  int _fogFocusEpochMs = 0;
  int _flashlightCharges = 1;
  int _flashlightUntilEpochMs = 0;

  int get fogFocusRow => _fogFocusRow;
  int get fogFocusCol => _fogFocusCol;
  int get fogFocusEpochMs => _fogFocusEpochMs;
  int get flashlightUntilEpochMs => _flashlightUntilEpochMs;
  int get flashlightCharges => _flashlightCharges;

  // ── Mentiroso (plan §2.4) ──────────────────────────────────────────
  int _scannerCharges = 3;
  bool _scannerMode = false;
  int get scannerCharges => _scannerCharges;
  bool get scannerMode => _scannerMode;

  // ── Oleadas (plan §2.5) ────────────────────────────────────────────
  int _wave = 1;
  int _lives = 3;
  int _wavesScore = 0;
  int _shield = 0; // cargas de escudo (absorben un error sin costar vida)
  bool _radar = false; // pasivo: marca 1 mina al inicio de cada oleada
  bool _vision = false; // una vez: revela zona segura al inicio de la próxima
  bool _awaitingUpgrade = false;
  List<WaveUpgrade> _upgradeChoices = const [];

  int get wave => _wave;
  int get lives => _lives;
  int get maxLives => _wavesEngine.maxLives;
  int get wavesScore => _wavesScore;
  int get shieldCharges => _shield;
  bool get awaitingUpgrade => _awaitingUpgrade;
  List<WaveUpgrade> get upgradeChoices => _upgradeChoices;

  // Modificadores de oleada ≥5 (§2.5).
  WaveModifier? _currentModifier;
  bool _wavePartialFog = false;
  bool _delayedPending = false; // hay minas con retardo por inyectar
  bool _delayedDone = false; // ya se inyectaron en esta oleada
  int _waveWarningUntilEpochMs = 0; // aviso transitorio de "minas nuevas"
  Timer? _warningTimer;

  WaveModifier? get currentModifier => _currentModifier;
  bool get wavePartialFog => _wavePartialFog;

  /// La niebla (visibilidad limitada) está activa: modo Niebla o modificador
  /// de niebla parcial en Oleadas.
  bool get fogActive => isFog || _wavePartialFog;

  /// Aviso transitorio tras inyectar minas con retardo.
  bool get waveWarningActive =>
      DateTime.now().millisecondsSinceEpoch < _waveWarningUntilEpochMs;

  /// Se incrementa cada vez que empieza un tablero nuevo (nueva partida o
  /// siguiente tablero de Blitz). El BoardWidget lo usa para limpiar sus
  /// animaciones de revelado entre tableros.
  int boardGeneration = 0;

  // ── Resultado ──────────────────────────────────────────────────────
  bool _isNewRecord = false;
  bool get isNewRecord => _isNewRecord;

  /// Celda de la mina que explotó (para resaltarla en la derrota).
  Cell? explodedCell;

  /// Última tanda de celdas reveladas, en orden BFS, para animar la cascada.
  List<Cell> lastRevealed = const [];

  /// Aumenta con cada revelado; el BoardWidget lo usa para detectar tandas
  /// nuevas y disparar la animación de ondas.
  int revealBatchId = 0;

  int get minesRemaining => _board.minesRemaining;

  bool get isTerminal =>
      _status == GameStatus.won || _status == GameStatus.lost;

  // ── Ciclo de vida del tablero ─────────────────────────────────────
  void _startNewBoard() {
    _board = Board.empty(
      rows: config.rows,
      cols: config.cols,
      mineCount: config.mines,
    );
    _minesPlaced = false;
    _status = GameStatus.idle;
    _isNewRecord = false;
    explodedCell = null;
    lastRevealed = const [];
    boardGeneration++;
    _scoring.reset();
    _timeBudgetMs = _blitzBudgetMs;
    // Cargas base + extra de consumibles comprados en la tienda (§3.1).
    _freezerCharges = 1 + _bonusFreezer;
    _timeUp = false;
    _usedAnyFlag = false;
    _fogFocusRow = -1;
    _fogFocusCol = -1;
    _fogFocusEpochMs = 0;
    _flashlightCharges = 1 + _bonusFlashlight;
    _flashlightUntilEpochMs = 0;
    _scannerCharges = 3 + _bonusScanner;
    _scannerMode = false;
    _stopwatch
      ..reset()
      ..stop();
    elapsed.value =
        isBlitz ? const Duration(milliseconds: _blitzBudgetMs) : Duration.zero;
    _stopTicker();
  }

  void restart() {
    if (isWaves) {
      _startWavesRun(resume: false); // reiniciar = nueva run desde la oleada 1
    } else if (isTower) {
      _startTower();
    } else {
      _startNewBoard();
    }
    notifyListeners();
  }

  // ── Torre 3D (plan §2.6) ───────────────────────────────────────────
  /// Genera la torre y activa la capa superior. Las minas van pre-colocadas
  /// (como Oleadas), con centro seguro por capa para arrancar.
  void _startTower() {
    _tower = _towerEngine.generate(
      layers: config.layers,
      rows: config.rows,
      cols: config.cols,
      minesPerLayer: config.mines,
      seed: config.seed,
    );
    _board = _tower!.active;
    _minesPlaced = true;
    _isNewRecord = false;
    _usedAnyFlag = false;
    explodedCell = null;
    lastRevealed = const [];
    boardGeneration++;
    _beginPlaying();
    _revealTowerFoothold();
  }

  /// Revela el centro seguro de la capa activa como punto de partida.
  void _revealTowerFoothold() {
    final cr = _board.rows ~/ 2;
    final cc = _board.cols ~/ 2;
    if (!_board.cellAt(cr, cc).isRevealed) _revealSilently(cr, cc);
  }

  /// Capa superada: si es la del fondo, la torre está completa (victoria); si
  /// no, desciende y la siguiente capa se vuelve jugable (plan §2.6).
  void _towerLayerComplete() {
    if (_tower!.isBottomActive) {
      _finish(GameStatus.won);
      return;
    }
    _tower!.activeLayer--;
    _board = _tower!.active;
    explodedCell = null;
    lastRevealed = const [];
    boardGeneration++;
    _revealTowerFoothold();
    notifyListeners();
  }

  /// Tocar una mina en la Torre derrumba la capa y termina la partida (§2.6).
  void _towerMineHit(Cell? mine) {
    explodedCell = mine;
    _engine.revealAllMines(_board);
    _finish(GameStatus.lost);
  }

  // ── Oleadas (plan §2.5) ────────────────────────────────────────────
  /// Arranca (o reanuda) una run de Oleadas y genera el tablero de la oleada.
  void _startWavesRun({required bool resume}) {
    final saved = resume ? _savegameRepo?.loadWaves() : null;
    if (saved != null) {
      _wave = (saved['wave'] as num?)?.toInt() ?? 1;
      _lives = (saved['lives'] as num?)?.toInt() ?? _wavesEngine.startLives;
      _wavesScore = (saved['score'] as num?)?.toInt() ?? 0;
      _shield = (saved['shield'] as num?)?.toInt() ?? 0;
      _radar = saved['radar'] as bool? ?? false;
      _vision = saved['vision'] as bool? ?? false;
    } else {
      _wave = 1;
      _lives = _wavesEngine.startLives;
      _wavesScore = 0;
      _shield = 0;
      _radar = false;
      _vision = false;
    }
    _isNewRecord = false;
    _awaitingUpgrade = false;
    _upgradeChoices = const [];

    // Restauración exacta: si el guardado trae el tablero en curso, se reanuda
    // tal cual (celdas, banderas, modificador); si no, se genera la oleada.
    final savedBoard = saved?['board'];
    if (savedBoard is Map) {
      _restoreWaveBoard(saved!);
    } else {
      _startWaveBoard();
    }
    _persistWaves();
  }

  /// Reanuda el tablero exacto de la oleada guardado en [saved] (§6.2), sin
  /// regenerar minas ni re-aplicar radar/visión (ya reflejados en las celdas).
  void _restoreWaveBoard(Map<String, dynamic> saved) {
    _board = Board.fromMap((saved['board'] as Map).cast<String, dynamic>());
    _minesPlaced = true;
    explodedCell = null;
    lastRevealed = const [];
    boardGeneration++;

    final modName = saved['modifier'] as String?;
    WaveModifier? mod;
    if (modName != null) {
      for (final m in WaveModifier.values) {
        if (m.name == modName) {
          mod = m;
          break;
        }
      }
    }
    _currentModifier = mod;
    _wavePartialFog = _currentModifier == WaveModifier.partialFog;
    _delayedPending = _currentModifier == WaveModifier.delayedMines;
    _delayedDone = saved['delayedDone'] as bool? ?? false;

    // Niebla parcial: reencuadrar el foco en el centro al reanudar.
    if (_wavePartialFog) {
      _setFogFocus(_board.rows ~/ 2, _board.cols ~/ 2);
    }

    _status = GameStatus.playing;

    // Si se cerró la app mientras se elegía mejora, se vuelve a ofrecer.
    final choiceNames = (saved['upgradeChoices'] as List?)?.cast<String>();
    if (choiceNames != null && choiceNames.isNotEmpty) {
      _upgradeChoices = [
        for (final n in choiceNames)
          WaveUpgrade.values.firstWhere((u) => u.name == n),
      ];
      _awaitingUpgrade = true;
    }
  }

  /// Genera el tablero de la oleada actual (eager, con centro seguro) y aplica
  /// los efectos de inicio de oleada (radar/visión). A diferencia del clásico,
  /// Oleadas coloca las minas al inicio para que radar/visión tengan sentido.
  void _startWaveBoard() {
    final spec = _wavesEngine.boardFor(_wave);
    final cr = spec.rows ~/ 2;
    final cc = spec.cols ~/ 2;

    // Modificador de oleada (≥5, §2.5). Puede forzarse en tests.
    _currentModifier =
        _debugForceModifier ?? _wavesEngine.modifierFor(_wave, _wavesRng);
    _wavePartialFog = _currentModifier == WaveModifier.partialFog;
    _delayedPending = _currentModifier == WaveModifier.delayedMines;
    _delayedDone = false;

    // "Minas encadenadas" cambia la colocación; el resto usan la normal.
    _board = _currentModifier == WaveModifier.chainedMines
        ? _generator.generateChained(
            rows: spec.rows,
            cols: spec.cols,
            mines: spec.mines,
            safeRow: cr,
            safeCol: cc,
          )
        : _generator.generate(
            rows: spec.rows,
            cols: spec.cols,
            mines: spec.mines,
            safeRow: cr,
            safeCol: cc,
          );

    // "Números mentirosos" (5%) reusa el LiarEngine sobre el tablero.
    if (_currentModifier == WaveModifier.liarNumbers) {
      const LiarEngine(liarRatio: 0.05)
          .applyLies(_board, seed: _wavesRng.nextInt(1 << 31));
    }

    _minesPlaced = true;
    _status = GameStatus.playing;
    explodedCell = null;
    lastRevealed = const [];
    boardGeneration++;

    // Foothold: revelar el centro seguro para arrancar la oleada.
    _revealSilently(cr, cc);
    // Niebla parcial: fijar el foco inicial en el centro.
    if (_wavePartialFog) _setFogFocus(cr, cc);
    // Radar pasivo: marca 1 mina al azar (§2.5).
    if (_radar) _flagRandomMine();
    // Visión (una vez): revela una zona 3×3 segura adicional.
    if (_vision) {
      _revealSafeZone();
      _vision = false;
    }
  }

  /// Revela una celda sin disparar la lógica de victoria/derrota (para el
  /// foothold y la Visión). La celda debe ser segura.
  void _revealSilently(int row, int col) {
    final result = _engine.reveal(_board, row, col);
    if (result.isNoop || result.hitMine) return;
    lastRevealed = result.revealed;
    revealBatchId++;
  }

  /// Marca con bandera una mina oculta al azar (Radar).
  void _flagRandomMine() {
    final mines = [
      for (final c in _board.cells)
        if (c.hasMine && !c.isFlagged && !c.isRevealed) c,
    ];
    if (mines.isEmpty) return;
    mines[_wavesRng.nextInt(mines.length)].isFlagged = true;
  }

  /// Busca una celda segura (0 minas alrededor, no revelada) y la revela con su
  /// zona en cascada (Visión).
  void _revealSafeZone() {
    for (final c in _board.cells) {
      if (!c.isRevealed && !c.hasMine && c.adjacentMines == 0) {
        _revealSilently(c.row, c.col);
        return;
      }
    }
  }

  /// Oleada superada: suma puntaje y ofrece 3 mejoras (§2.5).
  void _wavesWaveComplete() {
    final spec = _wavesEngine.boardFor(_wave);
    _wavesScore += _wavesEngine.waveScore(_wave, spec.cells);
    final available = WaveUpgrade.values.toSet();
    if (_lives >= _wavesEngine.maxLives) available.remove(WaveUpgrade.extraLife);
    _upgradeChoices = _wavesEngine.rollUpgrades(_wavesRng, available: available);
    _awaitingUpgrade = true;
    _persistWaves();
    notifyListeners();
  }

  /// Aplica la mejora elegida y avanza a la siguiente oleada.
  void chooseUpgrade(WaveUpgrade upgrade) {
    if (!_awaitingUpgrade) return;
    switch (upgrade) {
      case WaveUpgrade.extraLife:
        _lives = (_lives + 1).clamp(0, _wavesEngine.maxLives);
      case WaveUpgrade.shield:
      case WaveUpgrade.itemCharge:
        _shield++;
      case WaveUpgrade.radar:
        _radar = true;
      case WaveUpgrade.vision:
        _vision = true;
    }
    _wave++;
    _awaitingUpgrade = false;
    _upgradeChoices = const [];
    _startWaveBoard();
    _persistWaves();
    notifyListeners();
  }

  /// Impacto de mina en Oleadas: el Escudo lo absorbe; si no, cuesta una vida.
  /// Sin vidas → game over. La mina tocada se neutraliza (queda marcada).
  void _wavesMineHit(Cell? mine) {
    if (mine != null) {
      mine.isRevealed = false;
      mine.isFlagged = true; // mina conocida (neutralizada)
    }
    if (_shield > 0) {
      _shield--;
    } else {
      _lives--;
      if (_lives <= 0) {
        explodedCell = mine;
        _engine.revealAllMines(_board);
        _status = GameStatus.lost;
        final prev = _records.wavesBestScore;
        _records.recordWaves(_wavesScore);
        _isNewRecord = _wavesScore > prev;
        _savegameRepo?.clearWaves();
        _emitOutcome(won: false);
        notifyListeners();
        return;
      }
    }
    _persistWaves();
    notifyListeners();
  }

  void _persistWaves() {
    _savegameRepo?.saveWaves({
      'wave': _wave,
      'lives': _lives,
      'score': _wavesScore,
      'shield': _shield,
      'radar': _radar,
      'vision': _vision,
      // Estado exacto del tablero en curso (§6.2).
      'board': _board.toMap(),
      'modifier': _currentModifier?.name,
      'delayedDone': _delayedDone,
      if (_awaitingUpgrade)
        'upgradeChoices': [for (final u in _upgradeChoices) u.name],
    });
  }

  /// Blitz: prepara el siguiente tablero sin detener la partida ni el reloj.
  void _startFreshBlitzBoard() {
    _board = Board.empty(
      rows: config.rows,
      cols: config.cols,
      mineCount: config.mines,
    );
    _minesPlaced = false;
    explodedCell = null;
    lastRevealed = const [];
    boardGeneration++;
  }

  // ── Entrada del jugador ────────────────────────────────────────────
  /// Determina si un tap corto revela (`true`) o pone bandera (`false`),
  /// según el modo-bandera y la inversión de controles (plan §4.3).
  bool get _tapReveals => !_flagMode && !_invertControls;

  void onTap(int row, int col) {
    if (_awaitingUpgrade) return; // Oleadas: eligiendo mejora
    // Mentiroso: con el Escáner activo, el toque escanea en vez de revelar.
    if (isLiar && _scannerMode) {
      _scan(row, col);
      return;
    }
    if (_tapReveals) {
      _reveal(row, col);
    } else {
      _toggleFlag(row, col);
    }
  }

  void onLongPress(int row, int col) {
    if (_awaitingUpgrade) return;
    // El long-press hace lo contrario del tap.
    if (_tapReveals) {
      _toggleFlag(row, col);
    } else {
      _reveal(row, col);
    }
  }

  void onDoubleTap(int row, int col) {
    if (_awaitingUpgrade) return;
    if (_status != GameStatus.playing) return;
    final result = _engine.chord(_board, row, col);
    if (result.isNoop) return;
    if (fogActive) _setFogFocus(row, col);
    _applyReveal(result.revealed, result.hitMine);
  }

  void toggleFlagMode() {
    _flagMode = !_flagMode;
    notifyListeners();
  }

  /// Ítem Congelador (plan §3.1): suma 10s al presupuesto de Blitz. 1 carga.
  void useFreezer() {
    if (!isBlitz || _freezerCharges <= 0 || _status != GameStatus.playing) {
      return;
    }
    _freezerCharges--;
    _timeBudgetMs += _freezerBonusMs;
    _refreshCountdown();
    notifyListeners();
  }

  /// Ítem Linterna (plan §2.2/§3.1): ilumina todo el tablero 5s. 1 carga.
  void useFlashlight() {
    if (!isFog || _flashlightCharges <= 0 || _status != GameStatus.playing) {
      return;
    }
    _flashlightCharges--;
    _flashlightUntilEpochMs =
        DateTime.now().millisecondsSinceEpoch + _flashlightMs;
    notifyListeners();
  }

  /// Mentiroso: activa/desactiva el modo Escáner. Con él activo, el siguiente
  /// toque sobre una celda mentirosa revelada muestra su número real (§2.4).
  void toggleScanner() {
    if (!isLiar || _scannerCharges <= 0 || _status != GameStatus.playing) {
      return;
    }
    _scannerMode = !_scannerMode;
    notifyListeners();
  }

  /// Ítem Escáner de verdad (§3.1): corrige una celda mentirosa revelada,
  /// mostrando su número real y quitando la marca. Consume 1 carga. Tocar otra
  /// cosa solo cancela el modo Escáner (sin gastar carga).
  void _scan(int row, int col) {
    final cell = _board.cellAt(row, col);
    if (cell.isRevealed && cell.isLiar) {
      cell.displayedNumber = cell.adjacentMines;
      cell.isLiar = false;
      _scannerCharges--;
    }
    _scannerMode = false;
    notifyListeners();
  }

  // ── Acciones internas ──────────────────────────────────────────────
  void _reveal(int row, int col) {
    if (isTerminal || _status == GameStatus.paused) return;

    // Primer toque: se genera el tablero DESPUÉS, con esta celda segura.
    if (!_minesPlaced) {
      _placeMines(safeRow: row, safeCol: col);
      if (_status != GameStatus.playing) _beginPlaying();
    }

    final result = _engine.reveal(_board, row, col);
    if (result.isNoop) return;
    if (fogActive) _setFogFocus(row, col);
    _applyReveal(result.revealed, result.hitMine);
  }

  /// Niebla: mueve el foco de luz a la celda tocada y reinicia su temporizador.
  void _setFogFocus(int row, int col) {
    _fogFocusRow = row;
    _fogFocusCol = col;
    _fogFocusEpochMs = DateTime.now().millisecondsSinceEpoch;
  }

  void _applyReveal(List<Cell> revealed, bool hitMine) {
    lastRevealed = revealed;
    revealBatchId++;

    if (hitMine) {
      final mineCell = revealed.isNotEmpty ? revealed.last : null;
      if (isWaves) {
        _wavesMineHit(mineCell);
        return;
      }
      if (isTower) {
        _towerMineHit(mineCell);
        return;
      }
      explodedCell = mineCell;
      _engine.revealAllMines(_board);
      if (isBlitz) _scoring.breakCombo();
      _finish(GameStatus.lost);
      return;
    }

    if (isBlitz && revealed.isNotEmpty) {
      _scoring.registerReveal(revealed.length, _stopwatch.elapsedMilliseconds);
    }

    if (_engine.isWon(_board)) {
      if (isBlitz) {
        _blitzAdvance();
        return;
      }
      if (isWaves) {
        _wavesWaveComplete();
        return;
      }
      if (isTower) {
        _towerLayerComplete();
        return;
      }
      _finish(GameStatus.won);
      return;
    }

    // Oleadas: modificador "minas con retardo" — a mitad de la oleada aparecen
    // 3 minas nuevas con aviso (§2.5).
    if (isWaves) {
      _maybeInjectDelayedMines();
      _persistWaves(); // guardar el tablero exacto tras cada revelado (§6.2)
    }

    notifyListeners();
  }

  /// Inyecta minas con retardo cuando ya se reveló la mitad de las celdas
  /// seguras de la oleada. Solo una vez por oleada.
  void _maybeInjectDelayedMines() {
    if (!_delayedPending || _delayedDone) return;
    final safeTotal = _board.cells.where((c) => !c.hasMine).length;
    final safeRevealed =
        _board.cells.where((c) => c.isRevealed && !c.hasMine).length;
    if (safeRevealed * 2 < safeTotal) return; // aún no es la mitad

    _delayedDone = true;
    _wavesEngine.injectMines(_board, _wavesEngine.delayedMinesCount, _wavesRng);
    _flashWaveWarning();
  }

  /// Muestra el aviso transitorio de "minas nuevas" ~1.5s y notifica al expirar.
  void _flashWaveWarning() {
    _waveWarningUntilEpochMs =
        DateTime.now().millisecondsSinceEpoch + 1500;
    _warningTimer?.cancel();
    _warningTimer = Timer(const Duration(milliseconds: 1500), () {
      notifyListeners();
    });
  }

  /// Blitz: tablero completado → bono de tiempo, +1 al marcador y tablero nuevo.
  void _blitzAdvance() {
    _scoring.registerBoardCleared();
    _timeBudgetMs += _blitzBoardBonusMs;
    _refreshCountdown();
    _startFreshBlitzBoard();
    notifyListeners();
  }

  void _toggleFlag(int row, int col) {
    if (isTerminal || _status == GameStatus.paused) return;
    // Permitir marcar antes del primer revelado (aún sin minas colocadas).
    _engine.toggleFlag(_board, row, col);
    if (_board.cellAt(row, col).isFlagged) _usedAnyFlag = true;
    if (isWaves) _persistWaves(); // banderas también en el savegame exacto
    notifyListeners();
  }

  void _placeMines({required int safeRow, required int safeCol}) {
    final generated = _generator.generate(
      rows: config.rows,
      cols: config.cols,
      mines: config.mines,
      safeRow: safeRow,
      safeCol: safeCol,
      seed: config.seed,
    );
    // Conservar banderas puestas antes del primer toque.
    for (final old in _board.cells) {
      if (old.isFlagged) generated.cellAt(old.row, old.col).isFlagged = true;
    }
    _board = generated;
    _minesPlaced = true;

    // Mentiroso (§2.4): tras generar, marcar ~15% de números como mentirosos.
    if (isLiar) {
      _liarEngine.applyLies(
        _board,
        seed: config.seed ?? DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  // ── Cronómetro / estados ──────────────────────────────────────────
  void _beginPlaying() {
    _status = GameStatus.playing;
    _stopwatch
      ..reset()
      ..start();
    _startTicker();
  }

  int get _remainingMs =>
      (_timeBudgetMs - _stopwatch.elapsedMilliseconds).clamp(0, 1 << 31);

  void _refreshCountdown() {
    if (isBlitz) elapsed.value = Duration(milliseconds: _remainingMs);
  }

  /// Construye la instantánea del resultado para la economía/logros (§3.2).
  GameOutcome _buildOutcome({required bool won}) => GameOutcome(
        mode: config.mode,
        difficulty: difficulty,
        won: won,
        elapsed: elapsed.value,
        timeUp: _timeUp,
        usedFlags: _usedAnyFlag,
        blitzScore: _scoring.score,
        blitzBoards: _scoring.boardsSolved,
        wavesReached: _wave,
        wavesScore: _wavesScore,
        isDaily: _isDaily,
      );

  void _emitOutcome({required bool won}) =>
      _onGameEnd?.call(_buildOutcome(won: won));

  void _finish(GameStatus status) {
    _status = status;
    _stopwatch.stop();
    _stopTicker();

    if (isBlitz) {
      _isNewRecord = _finishBlitz();
      _emitOutcome(won: false);
      notifyListeners();
      return;
    }

    elapsed.value = _stopwatch.elapsed;
    // Solo el Clásico persiste récords por dificultad (récords puros, plan
    // §2.1). Niebla y demás modos usarán su propia economía (Fase 5).
    if (isClassicScored) {
      if (status == GameStatus.won) {
        _records.recordGame(
          difficulty: difficulty,
          won: true,
          elapsed: _stopwatch.elapsed,
        );
        // Récord tentativo mostrado de inmediato; la persistencia confirma aparte.
        final prev = _records.bestTimeMs(difficulty);
        _isNewRecord =
            prev == null || _stopwatch.elapsed.inMilliseconds <= prev;
      } else {
        _records.recordGame(
          difficulty: difficulty,
          won: false,
          elapsed: _stopwatch.elapsed,
        );
      }
    }
    _emitOutcome(won: status == GameStatus.won);
    notifyListeners();
  }

  /// Cierra una partida Blitz: fija el reloj en 0/restante y persiste el récord.
  bool _finishBlitz() {
    elapsed.value = Duration(milliseconds: _timeUp ? 0 : _remainingMs);
    final prevBest = _records.blitzBestScore;
    _records.recordBlitz(_scoring.score);
    return _scoring.score > prevBest;
  }

  void pause() {
    if (_status != GameStatus.playing) return;
    _status = GameStatus.paused;
    _stopwatch.stop();
    _stopTicker();
    notifyListeners();
  }

  void resume() {
    if (_status != GameStatus.paused) return;
    _status = GameStatus.playing;
    _stopwatch.start();
    _startTicker();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (isBlitz) {
        elapsed.value = Duration(milliseconds: _remainingMs);
        if (_remainingMs <= 0) {
          _timeUp = true;
          _finish(GameStatus.lost);
        }
      } else {
        elapsed.value = _stopwatch.elapsed;
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _stopTicker();
    _warningTimer?.cancel();
    elapsed.dispose();
    super.dispose();
  }
}
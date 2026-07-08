import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants/difficulty.dart';
import '../data/repositories/records_repository.dart';
import '../domain/engine/board_generator.dart';
import '../domain/engine/minesweeper_engine.dart';
import '../domain/engine/scoring.dart';
import '../domain/models/board.dart';
import '../domain/models/cell.dart';
import '../domain/models/game_config.dart';
import '../domain/models/game_mode.dart';
import '../domain/models/game_status.dart';

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
    bool invertControls = false,
    BoardGenerator generator = const BoardGenerator(),
    MinesweeperEngine engine = const MinesweeperEngine(),
  })  : _records = records,
        _invertControls = invertControls,
        _generator = generator,
        _engine = engine {
    _startNewBoard();
  }

  // Nota: se usa lista de inicialización (no initializing formals) a propósito,
  // para exponer nombres públicos de parámetros (records/generator/engine)
  // manteniendo los campos privados.
  // ignore_for_file: prefer_initializing_formals

  final GameConfig config;
  final Difficulty difficulty;

  final RecordsRepository _records;
  final BoardGenerator _generator;
  final MinesweeperEngine _engine;
  final bool _invertControls;

  // ── Constantes de Blitz (plan §2.3) ────────────────────────────────
  static const _blitzBudgetMs = 60000; // 60s iniciales
  static const _blitzBoardBonusMs = 20000; // +20s por tablero
  static const _freezerBonusMs = 10000; // Congelador: +10s

  static const _flashlightMs = 5000; // Linterna: ilumina 5s (§2.2)

  bool get isBlitz => config.mode == GameMode.blitz;
  bool get isFog => config.mode == GameMode.fog;
  bool get isClassicScored => config.mode == GameMode.classic;

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
    _freezerCharges = 1;
    _timeUp = false;
    _fogFocusRow = -1;
    _fogFocusCol = -1;
    _fogFocusEpochMs = 0;
    _flashlightCharges = 1;
    _flashlightUntilEpochMs = 0;
    _stopwatch
      ..reset()
      ..stop();
    elapsed.value =
        isBlitz ? const Duration(milliseconds: _blitzBudgetMs) : Duration.zero;
    _stopTicker();
  }

  void restart() {
    _startNewBoard();
    notifyListeners();
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
    if (_tapReveals) {
      _reveal(row, col);
    } else {
      _toggleFlag(row, col);
    }
  }

  void onLongPress(int row, int col) {
    // El long-press hace lo contrario del tap.
    if (_tapReveals) {
      _toggleFlag(row, col);
    } else {
      _reveal(row, col);
    }
  }

  void onDoubleTap(int row, int col) {
    if (_status != GameStatus.playing) return;
    final result = _engine.chord(_board, row, col);
    if (result.isNoop) return;
    if (isFog) _setFogFocus(row, col);
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
    if (isFog) _setFogFocus(row, col);
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
      explodedCell = revealed.isNotEmpty ? revealed.last : null;
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
      _finish(GameStatus.won);
      return;
    }
    notifyListeners();
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

  void _finish(GameStatus status) {
    _status = status;
    _stopwatch.stop();
    _stopTicker();

    if (isBlitz) {
      _isNewRecord = _finishBlitz();
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
    elapsed.dispose();
    super.dispose();
  }
}
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants/difficulty.dart';
import '../data/repositories/records_repository.dart';
import '../domain/engine/board_generator.dart';
import '../domain/engine/minesweeper_engine.dart';
import '../domain/models/board.dart';
import '../domain/models/cell.dart';
import '../domain/models/game_config.dart';
import '../domain/models/game_status.dart';

/// Estado de la partida actual (plan §6.3). **No contiene lógica de juego**:
/// orquesta el engine (Dart puro) ↔ la UI y notifica cambios. Se crea scoped a
/// `GameScreen` con `ChangeNotifierProvider` y se destruye al salir.
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

  // ── Estado observable ──────────────────────────────────────────────
  late Board _board;
  Board get board => _board;

  GameStatus _status = GameStatus.idle;
  GameStatus get status => _status;

  bool _flagMode = false;
  bool get flagMode => _flagMode;

  bool _minesPlaced = false;

  /// Cronómetro en su propio notificador → el HUD del tiempo se reconstruye
  /// solo, sin repintar el tablero (plan §6.3 regla 4).
  final ValueNotifier<Duration> elapsed = ValueNotifier(Duration.zero);
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;

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
    _stopwatch
      ..reset()
      ..stop();
    elapsed.value = Duration.zero;
    _stopTicker();
  }

  void restart() {
    _startNewBoard();
    notifyListeners();
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
    _applyReveal(result.revealed, result.hitMine);
  }

  void toggleFlagMode() {
    _flagMode = !_flagMode;
    notifyListeners();
  }

  // ── Acciones internas ──────────────────────────────────────────────
  void _reveal(int row, int col) {
    if (isTerminal || _status == GameStatus.paused) return;

    // Primer toque: se genera el tablero DESPUÉS, con esta celda segura.
    if (!_minesPlaced) {
      _placeMines(safeRow: row, safeCol: col);
      _beginPlaying();
    }

    final result = _engine.reveal(_board, row, col);
    if (result.isNoop) return;
    _applyReveal(result.revealed, result.hitMine);
  }

  void _applyReveal(List<Cell> revealed, bool hitMine) {
    lastRevealed = revealed;
    revealBatchId++;

    if (hitMine) {
      explodedCell = revealed.isNotEmpty ? revealed.last : null;
      _engine.revealAllMines(_board);
      _finish(GameStatus.lost);
      return;
    }
    if (_engine.isWon(_board)) {
      _finish(GameStatus.won);
      return;
    }
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

  void _finish(GameStatus status) {
    _status = status;
    _stopwatch.stop();
    _stopTicker();
    elapsed.value = _stopwatch.elapsed;
    if (status == GameStatus.won) {
      _records.recordGame(
        difficulty: difficulty,
        won: true,
        elapsed: _stopwatch.elapsed,
      );
      // Récord tentativo mostrado de inmediato; la persistencia confirma aparte.
      final prev = _records.bestTimeMs(difficulty);
      _isNewRecord = prev == null || _stopwatch.elapsed.inMilliseconds <= prev;
    } else {
      _records.recordGame(
        difficulty: difficulty,
        won: false,
        elapsed: _stopwatch.elapsed,
      );
    }
    notifyListeners();
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
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      elapsed.value = _stopwatch.elapsed;
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

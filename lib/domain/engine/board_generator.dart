import 'dart:math';

import '../models/board.dart';
import '../models/cell.dart';

/// Genera tableros de forma **determinista y pura** (sin Flutter).
///
/// Regla clave del clásico (plan §2.1): el tablero se genera DESPUÉS del primer
/// toque, garantizando que la celda tocada y sus 8 vecinas queden libres de
/// minas ("primer clic seguro").
///
/// Determinismo: con el mismo [seed] y la misma celda segura, el tablero
/// resultante es idéntico. Esto permite el Reto Diario y unit tests sin
/// emulador (plan §6.3, §10).
class BoardGenerator {
  const BoardGenerator();

  /// Crea un tablero de [rows]×[cols] con [mines] minas, dejando segura la
  /// celda ([safeRow], [safeCol]) y sus vecinas.
  ///
  /// - [seed]: si es `null` se usa una semilla aleatoria del sistema.
  /// - Lanza [ArgumentError] si no caben las minas fuera de la zona segura.
  Board generate({
    required int rows,
    required int cols,
    required int mines,
    required int safeRow,
    required int safeCol,
    int? seed,
  }) {
    final board = Board.empty(rows: rows, cols: cols, mineCount: mines);

    // Zona segura: la celda tocada + sus vecinas en rango.
    final safe = <int>{_index(safeRow, safeCol, cols)};
    for (final n in board.neighbors(board.cellAt(safeRow, safeCol))) {
      safe.add(_index(n.row, n.col, cols));
    }

    final totalCells = rows * cols;
    final available = totalCells - safe.length;
    if (mines > available) {
      throw ArgumentError(
        'No caben $mines minas: solo hay $available celdas fuera de la zona '
        'segura (${safe.length} celdas seguras de $totalCells).',
      );
    }

    // Candidatas = todas las celdas menos la zona segura.
    final candidates = <int>[
      for (var i = 0; i < totalCells; i++)
        if (!safe.contains(i)) i,
    ];

    // Barajado determinista (Fisher–Yates) con la semilla dada.
    final rng = Random(seed);
    _shuffle(candidates, rng);

    // Coloca las primeras [mines] candidatas como minas.
    for (var i = 0; i < mines; i++) {
      final idx = candidates[i];
      board.grid[idx ~/ cols][idx % cols].hasMine = true;
    }

    _computeAdjacency(board);
    return board;
  }

  /// Genera directamente sin restricción de celda segura (útil para tests o
  /// modos que no requieren primer clic seguro). Los números quedan calculados.
  Board generateRaw({
    required int rows,
    required int cols,
    required int mines,
    int? seed,
  }) {
    final board = Board.empty(rows: rows, cols: cols, mineCount: mines);
    final totalCells = rows * cols;
    if (mines > totalCells) {
      throw ArgumentError('No caben $mines minas en $totalCells celdas.');
    }
    final candidates = [for (var i = 0; i < totalCells; i++) i];
    final rng = Random(seed);
    _shuffle(candidates, rng);
    for (var i = 0; i < mines; i++) {
      final idx = candidates[i];
      board.grid[idx ~/ cols][idx % cols].hasMine = true;
    }
    _computeAdjacency(board);
    return board;
  }

  /// Recalcula [Cell.adjacentMines] de todas las celdas.
  void _computeAdjacency(Board board) {
    for (final cell in board.cells) {
      if (cell.hasMine) {
        cell.adjacentMines = 0;
        continue;
      }
      cell.adjacentMines =
          board.neighbors(cell).where((n) => n.hasMine).length;
    }
  }

  /// Fisher–Yates in-place con un [Random] inyectado (determinista por seed).
  void _shuffle(List<int> list, Random rng) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }

  int _index(int row, int col, int cols) => row * cols + col;
}

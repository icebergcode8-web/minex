import 'cell.dart';

/// El tablero de juego: una grilla de [Cell] de [rows]×[cols].
///
/// Modelo de datos puro (sin Flutter). El engine opera sobre él; la UI solo
/// lo lee. Las mutaciones de estado (revelar, marcar) las hacen las funciones
/// del engine, nunca la propia UI.
class Board {
  Board({
    required this.rows,
    required this.cols,
    required this.grid,
    required this.mineCount,
  });

  final int rows;
  final int cols;
  final int mineCount;

  /// Grilla indexada como `grid[row][col]`.
  final List<List<Cell>> grid;

  /// Crea un tablero vacío (sin minas, todo oculto) del tamaño dado.
  factory Board.empty({
    required int rows,
    required int cols,
    required int mineCount,
  }) {
    final grid = List.generate(
      rows,
      (r) => List.generate(cols, (c) => Cell(row: r, col: c)),
      growable: false,
    );
    return Board(rows: rows, cols: cols, grid: grid, mineCount: mineCount);
  }

  bool inBounds(int row, int col) =>
      row >= 0 && row < rows && col >= 0 && col < cols;

  Cell cellAt(int row, int col) => grid[row][col];

  /// Todas las celdas en orden fila-por-fila.
  Iterable<Cell> get cells sync* {
    for (final row in grid) {
      yield* row;
    }
  }

  /// Las hasta 8 celdas vecinas (ortogonales y diagonales) de [cell].
  Iterable<Cell> neighbors(Cell cell) sync* {
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final r = cell.row + dr;
        final c = cell.col + dc;
        if (inBounds(r, c)) yield grid[r][c];
      }
    }
  }

  int get revealedCount => cells.where((c) => c.isRevealed).length;

  int get flaggedCount => cells.where((c) => c.isFlagged).length;

  /// Minas restantes según banderas puestas (puede ser negativo si el jugador
  /// sobre-marca). La UI lo muestra en el contador del HUD.
  int get minesRemaining => mineCount - flaggedCount;
}

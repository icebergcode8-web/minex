import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:minex/domain/models/board.dart';
import 'package:minex/domain/models/cell.dart';

/// Round-trip de serialización del tablero para el savegame exacto (§6.2).
void main() {
  test('Board.toMap/fromMap conserva dimensiones y estado de cada celda', () {
    final board = Board.empty(rows: 3, cols: 4, mineCount: 2);
    // Estado variado para cubrir todos los campos serializados.
    board.cellAt(0, 0)
      ..hasMine = true
      ..isFlagged = true;
    board.cellAt(1, 2)
      ..isRevealed = true
      ..adjacentMines = 3;
    board.cellAt(2, 3)
      ..isRevealed = true
      ..adjacentMines = 2
      ..displayedNumber = 3
      ..isLiar = true;

    // Pasar por JSON como haría el repositorio.
    final restored = Board.fromMap(
      jsonDecode(jsonEncode(board.toMap())) as Map<String, dynamic>,
    );

    expect(restored.rows, 3);
    expect(restored.cols, 4);
    expect(restored.mineCount, 2);
    for (var r = 0; r < board.rows; r++) {
      for (var c = 0; c < board.cols; c++) {
        final a = board.cellAt(r, c);
        final b = restored.cellAt(r, c);
        expect(b.row, a.row);
        expect(b.col, a.col);
        expect(b.hasMine, a.hasMine);
        expect(b.isRevealed, a.isRevealed);
        expect(b.isFlagged, a.isFlagged);
        expect(b.adjacentMines, a.adjacentMines);
        expect(b.displayedNumber, a.displayedNumber);
        expect(b.isLiar, a.isLiar);
        expect(b.minedBelow, a.minedBelow);
      }
    }
  });

  test('una celda por defecto se serializa a un mapa vacío (compacto)', () {
    expect(Cell(row: 0, col: 0).toMap(), isEmpty);
  });
}
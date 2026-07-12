import 'package:flutter_test/flutter_test.dart';
import 'package:minex/domain/engine/board_generator.dart';
import 'package:minex/domain/engine/liar_engine.dart';
import 'package:minex/domain/models/board.dart';

void main() {
  const gen = BoardGenerator();
  const liar = LiarEngine(liarRatio: 0.15);

  Board freshBoard({int seed = 7}) => gen.generate(
        rows: 14,
        cols: 12,
        mines: 28,
        safeRow: 6,
        safeCol: 6,
        seed: seed,
      );

  test('marca ~15% de las celdas-número como mentirosas', () {
    final board = freshBoard();
    final numberCells =
        board.cells.where((c) => !c.hasMine && c.adjacentMines >= 1).length;
    final marked = liar.applyLies(board, seed: 1);
    expect(marked, (numberCells * 0.15).round());
    expect(board.cells.where((c) => c.isLiar).length, marked);
  });

  test('cada mentirosa muestra el real ±1 dentro de [1,8]', () {
    final board = freshBoard();
    liar.applyLies(board, seed: 2);
    for (final c in board.cells.where((c) => c.isLiar)) {
      expect(c.displayedNumber, isNotNull);
      final shown = c.displayedNumber!;
      expect((shown - c.adjacentMines).abs(), 1);
      expect(shown, inInclusiveRange(1, 8));
      expect(c.shownNumber, shown); // la UI muestra la mentira
    }
  });

  test('minas y celdas vacías nunca mienten', () {
    final board = freshBoard();
    liar.applyLies(board, seed: 3);
    for (final c in board.cells) {
      if (c.hasMine || c.adjacentMines == 0) {
        expect(c.isLiar, isFalse);
        expect(c.displayedNumber, isNull);
      }
    }
  });

  test('determinista: mismo tablero + seed → mismas mentiras', () {
    final a = freshBoard(seed: 9);
    final b = freshBoard(seed: 9);
    liar.applyLies(a, seed: 42);
    liar.applyLies(b, seed: 42);
    for (var r = 0; r < a.rows; r++) {
      for (var c = 0; c < a.cols; c++) {
        expect(a.cellAt(r, c).isLiar, b.cellAt(r, c).isLiar);
        expect(a.cellAt(r, c).displayedNumber, b.cellAt(r, c).displayedNumber);
      }
    }
  });
}
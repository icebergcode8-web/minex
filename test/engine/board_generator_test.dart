import 'package:flutter_test/flutter_test.dart';
import 'package:minex/domain/engine/board_generator.dart';
import 'package:minex/domain/models/board.dart';

void main() {
  const gen = BoardGenerator();

  int countMines(Board b) => b.cells.where((c) => c.hasMine).length;

  group('BoardGenerator.generate', () {
    test('coloca exactamente el número de minas pedido', () {
      final board = gen.generate(
        rows: 9,
        cols: 9,
        mines: 10,
        safeRow: 4,
        safeCol: 4,
        seed: 1,
      );
      expect(countMines(board), 10);
      expect(board.mineCount, 10);
    });

    test('primer clic seguro: la celda tocada y sus vecinas no tienen mina', () {
      // Probamos varias semillas para descartar suerte.
      for (var seed = 0; seed < 25; seed++) {
        final board = gen.generate(
          rows: 9,
          cols: 9,
          mines: 10,
          safeRow: 4,
          safeCol: 4,
          seed: seed,
        );
        final safe = board.cellAt(4, 4);
        expect(safe.hasMine, isFalse, reason: 'seed $seed: celda tocada');
        for (final n in board.neighbors(safe)) {
          expect(n.hasMine, isFalse, reason: 'seed $seed: vecina de la tocada');
        }
      }
    });

    test('primer clic seguro también en una esquina', () {
      final board = gen.generate(
        rows: 9,
        cols: 9,
        mines: 10,
        safeRow: 0,
        safeCol: 0,
        seed: 7,
      );
      final corner = board.cellAt(0, 0);
      expect(corner.hasMine, isFalse);
      for (final n in board.neighbors(corner)) {
        expect(n.hasMine, isFalse);
      }
    });

    test('es determinista: mismo seed y celda segura → mismo tablero', () {
      final a = gen.generate(
          rows: 12, cols: 12, mines: 20, safeRow: 6, safeCol: 6, seed: 42);
      final b = gen.generate(
          rows: 12, cols: 12, mines: 20, safeRow: 6, safeCol: 6, seed: 42);
      for (var r = 0; r < 12; r++) {
        for (var c = 0; c < 12; c++) {
          expect(a.cellAt(r, c).hasMine, b.cellAt(r, c).hasMine);
        }
      }
    });

    test('seeds distintos producen (casi siempre) tableros distintos', () {
      final a = gen.generate(
          rows: 16, cols: 16, mines: 40, safeRow: 8, safeCol: 8, seed: 1);
      final b = gen.generate(
          rows: 16, cols: 16, mines: 40, safeRow: 8, safeCol: 8, seed: 2);
      var diffs = 0;
      for (final ca in a.cells) {
        if (ca.hasMine != b.cellAt(ca.row, ca.col).hasMine) diffs++;
      }
      expect(diffs, greaterThan(0));
    });

    test('los números adyacentes son correctos', () {
      final board = gen.generate(
          rows: 10, cols: 10, mines: 15, safeRow: 5, safeCol: 5, seed: 99);
      for (final cell in board.cells) {
        if (cell.hasMine) continue;
        final expected = board.neighbors(cell).where((n) => n.hasMine).length;
        expect(cell.adjacentMines, expected,
            reason: 'celda (${cell.row},${cell.col})');
      }
    });

    test('lanza si las minas no caben fuera de la zona segura', () {
      expect(
        () => gen.generate(
            rows: 5, cols: 5, mines: 20, safeRow: 2, safeCol: 2, seed: 0),
        throwsArgumentError,
      );
    });
  });
}

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:minex/domain/engine/board_generator.dart';
import 'package:minex/domain/engine/waves_engine.dart';

void main() {
  const w = WavesEngine();
  const gen = BoardGenerator();

  group('WavesEngine.boardFor', () {
    test('la oleada 1 es 7×7 con 6 minas', () {
      final s = w.boardFor(1);
      expect(s.rows, 7);
      expect(s.cols, 7);
      expect(s.mines, 6);
    });

    test('crece alternando fila y columna', () {
      expect((w.boardFor(2).rows, w.boardFor(2).cols), (8, 7)); // +fila
      expect((w.boardFor(3).rows, w.boardFor(3).cols), (8, 8)); // +columna
      expect((w.boardFor(4).rows, w.boardFor(4).cols), (9, 8)); // +fila
      expect((w.boardFor(5).rows, w.boardFor(5).cols), (9, 9)); // +columna
    });

    test('la densidad de minas sube con la oleada', () {
      final d1 = w.boardFor(1).mines / w.boardFor(1).cells;
      final d5 = w.boardFor(5).mines / w.boardFor(5).cells;
      expect(d5, greaterThan(d1));
    });

    test('siempre deja al menos 9 celdas seguras', () {
      for (var wave = 1; wave <= 20; wave++) {
        final s = w.boardFor(wave);
        expect(s.mines, lessThanOrEqualTo(s.cells - 9));
      }
    });
  });

  group('WavesEngine.waveScore', () {
    test('es oleada × celdas', () {
      expect(w.waveScore(3, 64), 192);
    });
  });

  group('WavesEngine.rollUpgrades', () {
    test('ofrece 3 mejoras distintas', () {
      final ups = w.rollUpgrades(Random(1));
      expect(ups.length, 3);
      expect(ups.toSet().length, 3);
    });

    test('respeta el conjunto disponible', () {
      final ups = w.rollUpgrades(
        Random(1),
        available: {WaveUpgrade.shield, WaveUpgrade.radar},
      );
      expect(ups.length, 2);
      expect(ups.toSet(), {WaveUpgrade.shield, WaveUpgrade.radar});
    });
  });

  group('WavesEngine.modifiersActiveAt / modifierFor', () {
    test('se activan desde la oleada 5', () {
      expect(w.modifiersActiveAt(4), isFalse);
      expect(w.modifiersActiveAt(5), isTrue);
      expect(w.modifiersActiveAt(9), isTrue);
    });

    test('modifierFor es null antes de la 5 y no-null desde la 5', () {
      expect(w.modifierFor(4, Random(1)), isNull);
      expect(w.modifierFor(5, Random(1)), isNotNull);
    });
  });

  group('WavesEngine.injectMines', () {
    test('añade minas en celdas seguras ocultas y recalcula números', () {
      final board = gen.generate(
        rows: 9,
        cols: 9,
        mines: 8,
        safeRow: 4,
        safeCol: 4,
        seed: 3,
      );
      final before = board.cells.where((c) => c.hasMine).length;
      final injected = w.injectMines(board, 3, Random(1));
      expect(injected.length, 3);
      expect(board.cells.where((c) => c.hasMine).length, before + 3);
      // Las nuevas minas no caen en celdas reveladas ni marcadas.
      for (final c in injected) {
        expect(c.isRevealed, isFalse);
        expect(c.isFlagged, isFalse);
        expect(c.hasMine, isTrue);
      }
      // Adyacencia coherente: alguna celda vecina refleja las nuevas minas.
      final sample = injected.first;
      final neighbor = board.neighbors(sample).firstWhere((n) => !n.hasMine);
      expect(
        neighbor.adjacentMines,
        board.neighbors(neighbor).where((n) => n.hasMine).length,
      );
    });
  });

  group('BoardGenerator.generateChained', () {
    test('coloca exactamente las minas y respeta la zona segura', () {
      final board = gen.generateChained(
        rows: 10,
        cols: 10,
        mines: 20,
        safeRow: 5,
        safeCol: 5,
        seed: 7,
      );
      expect(board.cells.where((c) => c.hasMine).length, 20);
      // La celda segura y sus vecinas no tienen mina.
      expect(board.cellAt(5, 5).hasMine, isFalse);
      for (final n in board.neighbors(board.cellAt(5, 5))) {
        expect(n.hasMine, isFalse);
      }
    });

    test('las minas tienden a estar encadenadas (vecinas entre sí)', () {
      final board = gen.generateChained(
        rows: 12,
        cols: 12,
        mines: 30,
        safeRow: 6,
        safeCol: 6,
        seed: 11,
      );
      // La mayoría de minas tiene al menos una mina vecina (racimos).
      final mines = board.cells.where((c) => c.hasMine).toList();
      final withMineNeighbor = mines
          .where((m) => board.neighbors(m).any((n) => n.hasMine))
          .length;
      expect(withMineNeighbor, greaterThan(mines.length ~/ 2));
    });
  });
}
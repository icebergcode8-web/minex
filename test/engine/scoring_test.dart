import 'package:flutter_test/flutter_test.dart';
import 'package:minex/domain/engine/scoring.dart';

void main() {
  group('BlitzScoring', () {
    test('estado inicial: 0 puntos, ×1, sin tableros', () {
      final s = BlitzScoring();
      expect(s.score, 0);
      expect(s.multiplier, 1);
      expect(s.boardsSolved, 0);
    });

    test('revelar celdas suma celdas × multiplicador', () {
      final s = BlitzScoring();
      s.registerReveal(3, 0); // ×1
      expect(s.score, 3);
      expect(s.comboCount, 3);
      expect(s.multiplier, 1);
    });

    test('revelados rápidos encadenan y suben el multiplicador', () {
      final s = BlitzScoring(comboWindowMs: 1000);
      s.registerReveal(4, 0); // combo 4 → ×1
      s.registerReveal(4, 500); // combo 8 → ×2
      expect(s.multiplier, 2);
      s.registerReveal(6, 1000); // combo 14 → ×3
      expect(s.multiplier, 3);
      s.registerReveal(10, 1800); // combo 24 → ×5
      expect(s.multiplier, 5);
      // Puntos: 4*1 + 4*2 + 6*3 + 10*5 = 4+8+18+50 = 80.
      expect(s.score, 80);
    });

    test('una pausa mayor que la ventana reinicia el combo', () {
      final s = BlitzScoring(comboWindowMs: 1000);
      s.registerReveal(10, 0);
      s.registerReveal(20, 500); // combo 30 → ×5
      expect(s.multiplier, 5);
      s.registerReveal(3, 3000); // fuera de ventana → combo 3 → ×1
      expect(s.multiplier, 1);
      expect(s.comboCount, 3);
    });

    test('un error rompe el combo pero conserva el puntaje', () {
      final s = BlitzScoring(comboWindowMs: 1000);
      s.registerReveal(20, 0); // combo 20 → ×3
      final before = s.score;
      s.breakCombo();
      expect(s.multiplier, 1);
      expect(s.comboCount, 0);
      expect(s.score, before);
    });

    test('completar un tablero suma el bono', () {
      final s = BlitzScoring(boardBonus: 25);
      s.registerReveal(4, 0); // 4 celdas en ×1 = 4 puntos
      s.registerBoardCleared();
      expect(s.boardsSolved, 1);
      expect(s.score, 29);
    });

    test('comboProgress avanza entre escalones y se llena al máximo', () {
      final s = BlitzScoring(comboWindowMs: 100000);
      expect(s.comboProgress, 0); // combo 0 en [0,5)
      s.registerReveal(5, 0); // combo 5 → inicio del tramo [5,12)
      expect(s.comboProgress, 0);
      s.registerReveal(22, 1); // combo 27 → último escalón
      expect(s.multiplier, 5);
      expect(s.comboProgress, 1);
    });

    test('reset deja el marcador a cero', () {
      final s = BlitzScoring();
      s.registerReveal(10, 0);
      s.registerBoardCleared();
      s.reset();
      expect(s.score, 0);
      expect(s.boardsSolved, 0);
      expect(s.comboCount, 0);
      expect(s.multiplier, 1);
    });
  });
}
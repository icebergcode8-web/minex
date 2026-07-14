import 'package:flutter_test/flutter_test.dart';
import 'package:minex/domain/engine/tower_engine.dart';
import 'package:minex/domain/models/board.dart';
import 'package:minex/domain/models/tower.dart';

void main() {
  const engine = TowerEngine();

  Board empty3() => Board.empty(rows: 3, cols: 3, mineCount: 0);

  group('computeAdjacency (regla 3D, plan §2.6)', () {
    test('cuenta la mina de la celda directamente debajo y marca minedBelow', () {
      final bottom = empty3()..cellAt(0, 0).hasMine = true;
      final top = empty3();
      final tower = Tower(layers: [bottom, top], activeLayer: 1);

      engine.computeAdjacency(tower);

      // (0,0) de la cima: sin vecinas mina en su capa, pero mina debajo → 1.
      expect(top.cellAt(0, 0).adjacentMines, 1);
      expect(top.cellAt(0, 0).minedBelow, isTrue);
      // (2,2) de la cima: sin mina debajo ni vecinas → 0.
      expect(top.cellAt(2, 2).adjacentMines, 0);
      expect(top.cellAt(2, 2).minedBelow, isFalse);
    });

    test('suma vecinas de la capa + celda inferior', () {
      final bottom = empty3()..cellAt(0, 0).hasMine = true;
      final top = empty3()..cellAt(0, 1).hasMine = true;
      final tower = Tower(layers: [bottom, top], activeLayer: 1);

      engine.computeAdjacency(tower);

      // (0,0) cima: vecina (0,1) mina en su capa (1) + mina debajo (1) = 2.
      expect(top.cellAt(0, 0).adjacentMines, 2);
      expect(top.cellAt(0, 0).minedBelow, isTrue);
    });

    test('la capa del fondo no cuenta "debajo"', () {
      final bottom = empty3()..cellAt(1, 1).hasMine = true;
      final tower = Tower(layers: [bottom], activeLayer: 0);
      engine.computeAdjacency(tower);
      // (0,0) del fondo: solo vecina (1,1) mina → 1, sin minedBelow.
      expect(bottom.cellAt(0, 0).adjacentMines, 1);
      expect(bottom.cellAt(0, 0).minedBelow, isFalse);
    });
  });

  group('generate', () {
    test('produce N capas 8×8 con las minas pedidas y centro seguro', () {
      final tower = engine.generate(layers: 5, minesPerLayer: 10, seed: 42);
      expect(tower.layerCount, 5);
      expect(tower.activeLayer, 4); // arranca en la cima
      for (final layer in tower.layers) {
        expect(layer.rows, 8);
        expect(layer.cols, 8);
        expect(layer.cells.where((c) => c.hasMine).length, 10);
        // Centro seguro para poder arrancar.
        expect(layer.cellAt(4, 4).hasMine, isFalse);
      }
    });

    test('es determinista con la misma semilla', () {
      final a = engine.generate(layers: 3, minesPerLayer: 10, seed: 7);
      final b = engine.generate(layers: 3, minesPerLayer: 10, seed: 7);
      for (var l = 0; l < 3; l++) {
        final mA = a.layers[l].cells.where((c) => c.hasMine).map((c) => c.row * 8 + c.col).toList();
        final mB = b.layers[l].cells.where((c) => c.hasMine).map((c) => c.row * 8 + c.col).toList();
        expect(mA, mB);
      }
    });
  });
}
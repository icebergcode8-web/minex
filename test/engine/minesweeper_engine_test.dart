import 'package:flutter_test/flutter_test.dart';
import 'package:minex/domain/engine/minesweeper_engine.dart';
import 'package:minex/domain/models/board.dart';

/// Construye un tablero determinista con minas en [mines] (pares fila,col) y
/// calcula los números adyacentes. Evita depender del generador aleatorio.
Board buildBoard(int rows, int cols, List<List<int>> mines) {
  final board = Board.empty(rows: rows, cols: cols, mineCount: mines.length);
  for (final m in mines) {
    board.cellAt(m[0], m[1]).hasMine = true;
  }
  for (final cell in board.cells) {
    if (cell.hasMine) continue;
    cell.adjacentMines = board.neighbors(cell).where((n) => n.hasMine).length;
  }
  return board;
}

void main() {
  const engine = MinesweeperEngine();

  group('reveal', () {
    test('flood fill destapa toda la región vacía conectada y su borde', () {
      // Única mina en la esquina (0,0) de un 5×5: el resto es una región vacía
      // rodeada de números → un toque lejano destapa TODO el tablero.
      final board = buildBoard(5, 5, [
        [0, 0],
      ]);
      final result = engine.reveal(board, 4, 4);

      expect(result.hitMine, isFalse);
      // Se revelan las 24 celdas sin mina.
      expect(result.revealed.length, 24);
      expect(board.revealedCount, 24);
      expect(board.cellAt(0, 0).isRevealed, isFalse); // la mina no
    });

    test('revelar una celda-número no propaga a los vecinos', () {
      // Mina en (0,1): la celda (0,0) es un "1" adyacente.
      final board = buildBoard(5, 5, [
        [0, 1],
      ]);
      final result = engine.reveal(board, 0, 0);
      expect(result.hitMine, isFalse);
      expect(result.revealed.length, 1);
      expect(board.cellAt(0, 0).adjacentMines, 1);
    });

    test('revelar una mina devuelve hitMine', () {
      final board = buildBoard(5, 5, [
        [2, 2],
      ]);
      final result = engine.reveal(board, 2, 2);
      expect(result.hitMine, isTrue);
      expect(board.cellAt(2, 2).isRevealed, isTrue);
    });

    test('no hace nada sobre una celda marcada con bandera', () {
      final board = buildBoard(5, 5, [
        [0, 0],
      ]);
      engine.toggleFlag(board, 2, 2);
      final result = engine.reveal(board, 2, 2);
      expect(result.isNoop, isTrue);
      expect(board.cellAt(2, 2).isRevealed, isFalse);
    });

    test('el orden BFS empieza por la celda tocada', () {
      final board = buildBoard(5, 5, [
        [0, 0],
      ]);
      final result = engine.reveal(board, 4, 4);
      expect(result.revealed.first.row, 4);
      expect(result.revealed.first.col, 4);
    });
  });

  group('toggleFlag', () {
    test('alterna bandera en celda oculta', () {
      final board = buildBoard(5, 5, [
        [0, 0],
      ]);
      expect(engine.toggleFlag(board, 1, 1), isTrue);
      expect(board.cellAt(1, 1).isFlagged, isTrue);
      expect(engine.toggleFlag(board, 1, 1), isFalse);
      expect(board.cellAt(1, 1).isFlagged, isFalse);
    });

    test('no marca una celda ya revelada', () {
      final board = buildBoard(5, 5, [
        [0, 1],
      ]);
      engine.reveal(board, 0, 0);
      expect(engine.toggleFlag(board, 0, 0), isFalse);
      expect(board.cellAt(0, 0).isFlagged, isFalse);
    });
  });

  group('chord', () {
    test('con banderas correctas revela las vecinas restantes', () {
      // Mina en (0,0). (1,1) es un "1". Marcamos (0,0) y revelamos (1,1),
      // luego chording en (1,1) debe destapar el resto sin explotar.
      final board = buildBoard(5, 5, [
        [0, 0],
      ]);
      engine.reveal(board, 1, 1);
      engine.toggleFlag(board, 0, 0);
      final result = engine.chord(board, 1, 1);
      expect(result.hitMine, isFalse);
      expect(result.revealed, isNotEmpty);
    });

    test('con una bandera mal puesta el chording explota', () {
      // Mina real en (0,0), pero marcamos por error (0,1). El "1" en (1,1)
      // tiene 1 bandera → chording destapa (0,0) y explota.
      final board = buildBoard(5, 5, [
        [0, 0],
      ]);
      engine.reveal(board, 1, 1);
      engine.toggleFlag(board, 0, 1); // bandera equivocada
      final result = engine.chord(board, 1, 1);
      expect(result.hitMine, isTrue);
    });

    test('no hace nada si el número de banderas no coincide', () {
      final board = buildBoard(5, 5, [
        [0, 0],
      ]);
      engine.reveal(board, 1, 1); // un "1", sin banderas alrededor
      final result = engine.chord(board, 1, 1);
      expect(result.isNoop, isTrue);
    });
  });

  group('isWon', () {
    test('gana cuando todas las celdas sin mina están reveladas', () {
      final board = buildBoard(3, 3, [
        [0, 0],
      ]);
      expect(engine.isWon(board), isFalse);
      // Revela todo lo no-mina (un toque en zona vacía basta aquí).
      engine.reveal(board, 2, 2);
      expect(engine.isWon(board), isTrue);
    });

    test('no gana si queda una celda segura sin revelar', () {
      final board = buildBoard(3, 3, [
        [0, 0],
      ]);
      engine.reveal(board, 2, 2);
      // Fuerza un estado imposible sano: oculta una celda y verifica.
      board.cellAt(2, 2).isRevealed = false;
      expect(engine.isWon(board), isFalse);
    });
  });

  group('revealAllMines', () {
    test('revela todas las minas', () {
      final board = buildBoard(5, 5, [
        [0, 0],
        [4, 4],
        [2, 3],
      ]);
      final mines = engine.revealAllMines(board);
      expect(mines.length, 3);
      expect(mines.every((m) => m.isRevealed && m.hasMine), isTrue);
    });
  });
}

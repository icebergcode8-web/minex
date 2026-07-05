import 'dart:collection';

import '../models/board.dart';
import '../models/cell.dart';

/// Resultado de una operación de revelado.
///
/// [revealed] lista las celdas destapadas **en orden BFS desde el punto de
/// toque**, para que la UI las anime en ondas (la animación firma del juego,
/// plan §5.2 "revelado en cascada").
class RevealResult {
  const RevealResult({required this.revealed, required this.hitMine});

  final List<Cell> revealed;
  final bool hitMine;

  bool get isNoop => revealed.isEmpty && !hitMine;

  static const empty = RevealResult(revealed: [], hitMine: false);
}

/// Motor del buscaminas clásico: **lógica pura y determinista, sin Flutter**
/// (plan §6.3). Todas las operaciones mutan el [Board] recibido y devuelven qué
/// cambió, sin conocer nada de UI ni de persistencia.
class MinesweeperEngine {
  const MinesweeperEngine();

  /// Revela la celda ([row], [col]).
  ///
  /// - Si está marcada o ya revelada: no-op.
  /// - Si tiene mina: la revela y devuelve `hitMine: true` (fin de partida).
  /// - Si es un número: revela solo esa celda.
  /// - Si es vacía (0 adyacentes): flood fill BFS a la región conectada.
  RevealResult reveal(Board board, int row, int col) {
    if (!board.inBounds(row, col)) return RevealResult.empty;
    final start = board.cellAt(row, col);
    if (start.isRevealed || start.isFlagged) return RevealResult.empty;

    if (start.hasMine) {
      start.isRevealed = true;
      return RevealResult(revealed: [start], hitMine: true);
    }

    final revealed = <Cell>[];
    final queue = Queue<Cell>();
    start.isRevealed = true;
    queue.add(start);

    while (queue.isNotEmpty) {
      final cell = queue.removeFirst();
      revealed.add(cell);
      // Solo las celdas vacías (0 adyacentes) propagan el destapado.
      if (cell.adjacentMines == 0) {
        for (final n in board.neighbors(cell)) {
          if (!n.isRevealed && !n.isFlagged && !n.hasMine) {
            n.isRevealed = true; // marcar al encolar evita duplicados
            queue.add(n);
          }
        }
      }
    }
    return RevealResult(revealed: revealed, hitMine: false);
  }

  /// Alterna la bandera de una celda no revelada. Devuelve el nuevo estado
  /// (`true` = quedó marcada). Si la celda ya está revelada, no hace nada.
  bool toggleFlag(Board board, int row, int col) {
    if (!board.inBounds(row, col)) return false;
    final cell = board.cellAt(row, col);
    if (cell.isRevealed) return cell.isFlagged;
    cell.isFlagged = !cell.isFlagged;
    return cell.isFlagged;
  }

  /// Chording (plan §2.1): sobre un número ya revelado cuyas banderas
  /// alrededor igualan su valor, revela todas las vecinas no marcadas.
  ///
  /// Si alguna bandera estaba mal puesta, se destapa una mina y
  /// `hitMine: true`.
  RevealResult chord(Board board, int row, int col) {
    if (!board.inBounds(row, col)) return RevealResult.empty;
    final cell = board.cellAt(row, col);
    if (!cell.isRevealed || cell.adjacentMines == 0) return RevealResult.empty;

    final flagged = board.neighbors(cell).where((n) => n.isFlagged).length;
    if (flagged != cell.adjacentMines) return RevealResult.empty;

    final all = <Cell>[];
    var hitMine = false;
    for (final n in board.neighbors(cell)) {
      if (!n.isFlagged && !n.isRevealed) {
        final result = reveal(board, n.row, n.col);
        all.addAll(result.revealed);
        if (result.hitMine) hitMine = true;
      }
    }
    return RevealResult(revealed: all, hitMine: hitMine);
  }

  /// Condición de victoria: todas las celdas sin mina están reveladas.
  bool isWon(Board board) {
    for (final cell in board.cells) {
      if (!cell.hasMine && !cell.isRevealed) return false;
    }
    return true;
  }

  /// Revela todas las minas del tablero (para la animación de derrota,
  /// plan §5.2). Devuelve las minas en orden fila-por-fila.
  List<Cell> revealAllMines(Board board) {
    final mines = <Cell>[];
    for (final cell in board.cells) {
      if (cell.hasMine) {
        cell.isRevealed = true;
        mines.add(cell);
      }
    }
    return mines;
  }
}

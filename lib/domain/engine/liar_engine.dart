import 'dart:math';

import '../models/board.dart';

/// Capa de números mentirosos del modo Mentiroso (plan §2.4). **Lógica pura,
/// sin Flutter** (CLAUDE.md): opera sobre un [Board] ya generado (con
/// `adjacentMines` reales) y marca una fracción de sus celdas-número como
/// mentirosas, fijando su `displayedNumber` a un valor falso.
///
/// Reglas (§2.4):
/// - Alrededor del [liarRatio] (15%) de los números mienten.
/// - El número mostrado difiere del real en ±1, acotado a `[1, 8]` para no
///   mostrar un "0" (que en buscaminas significa celda vacía).
/// - Solo mienten celdas-número (sin mina y con `adjacentMines >= 1`); las
///   minas y las celdas vacías nunca mienten.
/// - Determinista con [seed]: mismo tablero + seed → mismas mentiras.
class LiarEngine {
  const LiarEngine({this.liarRatio = 0.15});

  /// Fracción de celdas-número que mienten.
  final double liarRatio;

  /// Marca las celdas mentirosas de [board] de forma determinista con [seed].
  /// Devuelve cuántas celdas quedaron mintiendo.
  int applyLies(Board board, {required int seed}) {
    final rng = Random(seed);
    final candidates = [
      for (final c in board.cells)
        if (!c.hasMine && c.adjacentMines >= 1) c,
    ]..shuffle(rng);

    final count = (candidates.length * liarRatio).round();
    for (var i = 0; i < count && i < candidates.length; i++) {
      final cell = candidates[i];
      cell.isLiar = true;
      cell.displayedNumber = _lie(cell.adjacentMines, rng);
    }
    return count.clamp(0, candidates.length);
  }

  /// Devuelve un valor falso: el real ±1, acotado a `[1, 8]`.
  int _lie(int real, Random rng) {
    if (real <= 1) return real + 1; // 1 → 2 (no bajar a 0)
    if (real >= 8) return real - 1; // 8 → 7 (no subir a 9)
    return rng.nextBool() ? real + 1 : real - 1;
  }
}
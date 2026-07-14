import '../models/board.dart';
import '../models/tower.dart';
import 'board_generator.dart';

/// Lógica pura del modo 3D "Torre de Minas" (plan §2.6). Sin Flutter.
///
/// Regla clave: el número de una celda cuenta sus **8 vecinas de la misma capa
/// más la celda directamente debajo** (9 vecinas totales). Cuando esa celda
/// inferior es mina, se marca [Cell.minedBelow] para que la UI dibuje el punto
/// indicador. Determinista con [seed] → 100% testeable (plan §10).
class TowerEngine {
  const TowerEngine({this.generator = const BoardGenerator()});

  final BoardGenerator generator;

  /// Genera la torre completa: cada capa es un tablero [rows]×[cols] con
  /// [minesPerLayer] minas y centro seguro (para poder arrancar), y luego se
  /// recalcula la adyacencia 3D. La capa activa inicial es la superior.
  Tower generate({
    required int layers,
    int rows = 8,
    int cols = 8,
    required int minesPerLayer,
    int? seed,
  }) {
    final boards = <Board>[
      for (var l = 0; l < layers; l++)
        generator.generate(
          rows: rows,
          cols: cols,
          mines: minesPerLayer,
          safeRow: rows ~/ 2,
          safeCol: cols ~/ 2,
          // Semilla desplazada por capa: determinista pero distinta por nivel.
          seed: seed == null ? null : seed + l * 7919,
        ),
    ];
    final tower = Tower(layers: boards, activeLayer: layers - 1);
    computeAdjacency(tower);
    return tower;
  }

  /// Recalcula [Cell.adjacentMines] y [Cell.minedBelow] de todas las capas con
  /// la regla 3D: 8 vecinas de la capa + la celda inmediatamente inferior.
  void computeAdjacency(Tower tower) {
    for (var l = 0; l < tower.layerCount; l++) {
      final board = tower.layers[l];
      final below = l > 0 ? tower.layers[l - 1] : null;
      for (final cell in board.cells) {
        if (cell.hasMine) {
          cell.adjacentMines = 0;
          cell.minedBelow = false;
          continue;
        }
        var count = board.neighbors(cell).where((n) => n.hasMine).length;
        final hasBelow = below != null && below.cellAt(cell.row, cell.col).hasMine;
        if (hasBelow) count++;
        cell.adjacentMines = count;
        cell.minedBelow = hasBelow;
      }
    }
  }
}
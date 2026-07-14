import 'board.dart';

/// Torre de capas apiladas del modo 3D (plan §2.6). Modelo de datos puro (sin
/// Flutter). Índice 0 = capa inferior; `layerCount-1` = capa superior. Solo
/// [active] es jugable; se empieza por la de arriba y se desciende al completar.
class Tower {
  Tower({required this.layers, required this.activeLayer});

  final List<Board> layers;

  /// Capa jugable actual. Empieza en la superior y decrece al completar capas.
  int activeLayer;

  int get layerCount => layers.length;

  Board get active => layers[activeLayer];

  /// Capa físicamente debajo de la activa (la que cuentan los números "debajo"),
  /// o `null` si la activa es la del fondo.
  Board? get below => activeLayer > 0 ? layers[activeLayer - 1] : null;

  /// `true` si la activa es la capa del fondo (no hay más debajo).
  bool get isBottomActive => activeLayer == 0;

  /// Posición de la capa activa contada desde arriba (1 = cima). Para el HUD.
  int get displayLayer => layerCount - activeLayer;
}
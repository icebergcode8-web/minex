/// Skins de tablero comprables en la tienda (plan §3.2). Datos puros (sin
/// Flutter): identidad, coste y nombre localizado. El mapeo a colores concretos
/// vive en `core/theme/skins.dart` (capa de presentación).
enum BoardSkin { classic, neon, paper, pixel, ocean, space }

extension BoardSkinInfo on BoardSkin {
  /// Identificador estable para persistir en Hive.
  String get id => name;

  /// Coste en monedas. `classic` es gratis y viene equipado por defecto.
  int get cost => switch (this) {
        BoardSkin.classic => 0,
        BoardSkin.neon => 150,
        BoardSkin.paper => 160,
        BoardSkin.pixel => 200,
        BoardSkin.ocean => 250,
        BoardSkin.space => 300,
      };

  String get emoji => switch (this) {
        BoardSkin.classic => '🪟',
        BoardSkin.neon => '🌆',
        BoardSkin.paper => '📄',
        BoardSkin.pixel => '👾',
        BoardSkin.ocean => '🌊',
        BoardSkin.space => '🌌',
      };

  /// Nombre localizado. Los catálogos grandes (skins/logros) se localizan aquí
  /// —no en el ARB— para no inflar los recursos de UI con decenas de claves.
  String displayName(String locale) {
    final es = switch (this) {
      BoardSkin.classic => 'Clásico Windows',
      BoardSkin.neon => 'Neón oscuro',
      BoardSkin.paper => 'Papel / sketch',
      BoardSkin.pixel => 'Pixel retro',
      BoardSkin.ocean => 'Océano',
      BoardSkin.space => 'Espacial',
    };
    final en = switch (this) {
      BoardSkin.classic => 'Classic Windows',
      BoardSkin.neon => 'Dark neon',
      BoardSkin.paper => 'Paper / sketch',
      BoardSkin.pixel => 'Retro pixel',
      BoardSkin.ocean => 'Ocean',
      BoardSkin.space => 'Space',
    };
    return locale == 'en' ? en : es;
  }

  static BoardSkin fromId(String? id) => BoardSkin.values.firstWhere(
        (s) => s.id == id,
        orElse: () => BoardSkin.classic,
      );
}
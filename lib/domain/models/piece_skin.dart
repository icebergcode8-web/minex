/// Skins de banderas y minas (plan §3.2). Datos puros; el mapeo a colores/estilo
/// concreto vive en `core/theme/skins.dart`.
enum PieceSkin { classic, gold, neon, blossom }

extension PieceSkinInfo on PieceSkin {
  String get id => name;

  int get cost => switch (this) {
        PieceSkin.classic => 0,
        PieceSkin.gold => 120,
        PieceSkin.neon => 150,
        PieceSkin.blossom => 150,
      };

  String get emoji => switch (this) {
        PieceSkin.classic => '🚩',
        PieceSkin.gold => '🏅',
        PieceSkin.neon => '💠',
        PieceSkin.blossom => '🌸',
      };

  String displayName(String locale) {
    final es = switch (this) {
      PieceSkin.classic => 'Clásico',
      PieceSkin.gold => 'Oro',
      PieceSkin.neon => 'Neón',
      PieceSkin.blossom => 'Flor',
    };
    final en = switch (this) {
      PieceSkin.classic => 'Classic',
      PieceSkin.gold => 'Gold',
      PieceSkin.neon => 'Neon',
      PieceSkin.blossom => 'Blossom',
    };
    return locale == 'en' ? en : es;
  }

  static PieceSkin fromId(String? id) => PieceSkin.values.firstWhere(
        (s) => s.id == id,
        orElse: () => PieceSkin.classic,
      );
}
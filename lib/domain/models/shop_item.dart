import 'game_mode.dart';

/// Recargas de ítems comprables (plan §3.1/§3.2). Cada compra añade una carga
/// extra al inventario, que se aplica como carga inicial adicional del ítem del
/// modo correspondiente. Datos puros.
enum ShopConsumable { flashlight, freezer, scanner }

extension ShopConsumableInfo on ShopConsumable {
  String get id => name;

  int get cost => switch (this) {
        ShopConsumable.flashlight => 40,
        ShopConsumable.freezer => 40,
        ShopConsumable.scanner => 30,
      };

  String get emoji => switch (this) {
        ShopConsumable.flashlight => '🔦',
        ShopConsumable.freezer => '❄️',
        ShopConsumable.scanner => '🔍',
      };

  /// Modo en el que la carga extra tiene efecto.
  GameMode get mode => switch (this) {
        ShopConsumable.flashlight => GameMode.fog,
        ShopConsumable.freezer => GameMode.blitz,
        ShopConsumable.scanner => GameMode.liar,
      };

  String displayName(String locale) {
    final es = switch (this) {
      ShopConsumable.flashlight => 'Linterna',
      ShopConsumable.freezer => 'Congelador',
      ShopConsumable.scanner => 'Escáner',
    };
    final en = switch (this) {
      ShopConsumable.flashlight => 'Flashlight',
      ShopConsumable.freezer => 'Freezer',
      ShopConsumable.scanner => 'Scanner',
    };
    return locale == 'en' ? en : es;
  }

  String description(String locale) {
    final es = switch (this) {
      ShopConsumable.flashlight => 'Ilumina todo el tablero 5s (Niebla).',
      ShopConsumable.freezer => 'Pausa el reloj 10s (Blitz).',
      ShopConsumable.scanner => 'Revela el número real de una mentirosa.',
    };
    final en = switch (this) {
      ShopConsumable.flashlight => 'Lights up the whole board 5s (Fog).',
      ShopConsumable.freezer => 'Pauses the clock 10s (Blitz).',
      ShopConsumable.scanner => 'Reveals a liar cell\'s real number.',
    };
    return locale == 'en' ? en : es;
  }

  static ShopConsumable? fromId(String? id) {
    for (final c in ShopConsumable.values) {
      if (c.id == id) return c;
    }
    return null;
  }
}
import '../../domain/models/board_skin.dart';
import '../../domain/models/piece_skin.dart';
import '../local/hive_service.dart';

/// Monedas, inventario de consumibles y skins (plan §3.2). Única capa que toca
/// `economyBox`. Guarda todo como primitivos / listas de strings (sin
/// TypeAdapters, plan §6.2). Las skins `classic` vienen desbloqueadas y
/// equipadas por defecto.
class EconomyRepository {
  EconomyRepository(this._hive);

  final HiveService _hive;

  static const _kCoins = 'coins';
  static const _kEarned = 'coinsEarned';
  static const _kOwnedBoard = 'ownedBoardSkins';
  static const _kOwnedPiece = 'ownedPieceSkins';
  static const _kEquipBoard = 'equipBoardSkin';
  static const _kEquipPiece = 'equipPieceSkin';
  static String _consumableKey(String id) => 'consumable_$id';

  // ── Monedas ─────────────────────────────────────────────────────────
  int get coins => _hive.economy.get(_kCoins, defaultValue: 0);

  /// Monedas ganadas en total (histórico, para logros). Nunca decrece.
  int get totalEarned => _hive.economy.get(_kEarned, defaultValue: 0);

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    await _hive.economy.put(_kCoins, coins + amount);
    await _hive.economy.put(_kEarned, totalEarned + amount);
  }

  bool canAfford(int cost) => coins >= cost;

  /// Gasta [cost] monedas si alcanza. Devuelve `true` si se realizó el cobro.
  Future<bool> spend(int cost) async {
    if (coins < cost) return false;
    await _hive.economy.put(_kCoins, coins - cost);
    return true;
  }

  // ── Skins de tablero ────────────────────────────────────────────────
  Set<String> get ownedBoardSkins {
    final list = (_hive.economy.get(_kOwnedBoard) as List?)?.cast<String>();
    return {BoardSkin.classic.id, ...?list};
  }

  Future<void> addOwnedBoardSkin(String id) async {
    final set = ownedBoardSkins..add(id);
    await _hive.economy.put(_kOwnedBoard, set.toList());
  }

  String get equippedBoardSkinId =>
      _hive.economy.get(_kEquipBoard, defaultValue: BoardSkin.classic.id);

  Future<void> setEquippedBoardSkin(String id) =>
      _hive.economy.put(_kEquipBoard, id);

  // ── Skins de piezas ─────────────────────────────────────────────────
  Set<String> get ownedPieceSkins {
    final list = (_hive.economy.get(_kOwnedPiece) as List?)?.cast<String>();
    return {PieceSkin.classic.id, ...?list};
  }

  Future<void> addOwnedPieceSkin(String id) async {
    final set = ownedPieceSkins..add(id);
    await _hive.economy.put(_kOwnedPiece, set.toList());
  }

  String get equippedPieceSkinId =>
      _hive.economy.get(_kEquipPiece, defaultValue: PieceSkin.classic.id);

  Future<void> setEquippedPieceSkin(String id) =>
      _hive.economy.put(_kEquipPiece, id);

  // ── Consumibles (recargas de ítems) ─────────────────────────────────
  int consumableCount(String id) =>
      _hive.economy.get(_consumableKey(id), defaultValue: 0);

  Future<void> addConsumable(String id, [int n = 1]) =>
      _hive.economy.put(_consumableKey(id), consumableCount(id) + n);

  /// Consume hasta [max] cargas de un consumible; devuelve cuántas se gastaron.
  Future<int> consume(String id, int max) async {
    final have = consumableCount(id);
    final used = have < max ? have : max;
    if (used > 0) await _hive.economy.put(_consumableKey(id), have - used);
    return used;
  }
}
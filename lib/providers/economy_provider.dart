import 'package:flutter/foundation.dart';

import '../data/repositories/economy_repository.dart';
import '../domain/models/board_skin.dart';
import '../domain/models/game_mode.dart';
import '../domain/models/piece_skin.dart';
import '../domain/models/shop_item.dart';

/// Estado global de la economía (plan §3.2): monedas, skins e inventario de
/// consumibles. Orquesta [EconomyRepository]; no contiene reglas de juego.
class EconomyProvider extends ChangeNotifier {
  EconomyProvider(this._repo);

  final EconomyRepository _repo;

  int get coins => _repo.coins;
  int get totalEarned => _repo.totalEarned;

  /// Suma monedas (recompensas de partida, logros, racha) y notifica.
  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    await _repo.addCoins(amount);
    notifyListeners();
  }

  // ── Skins ───────────────────────────────────────────────────────────
  Set<String> get ownedBoardSkins => _repo.ownedBoardSkins;
  Set<String> get ownedPieceSkins => _repo.ownedPieceSkins;

  bool ownsBoardSkin(BoardSkin s) => ownedBoardSkins.contains(s.id);
  bool ownsPieceSkin(PieceSkin s) => ownedPieceSkins.contains(s.id);

  BoardSkin get equippedBoardSkin =>
      BoardSkinInfo.fromId(_repo.equippedBoardSkinId);
  PieceSkin get equippedPieceSkin =>
      PieceSkinInfo.fromId(_repo.equippedPieceSkinId);

  /// Compra una skin de tablero si alcanza el saldo y no se posee. `true` si se
  /// realizó la compra.
  Future<bool> buyBoardSkin(BoardSkin s) async {
    if (ownsBoardSkin(s)) return false;
    if (!await _repo.spend(s.cost)) return false;
    await _repo.addOwnedBoardSkin(s.id);
    notifyListeners();
    return true;
  }

  Future<void> equipBoardSkin(BoardSkin s) async {
    if (!ownsBoardSkin(s)) return;
    await _repo.setEquippedBoardSkin(s.id);
    notifyListeners();
  }

  Future<bool> buyPieceSkin(PieceSkin s) async {
    if (ownsPieceSkin(s)) return false;
    if (!await _repo.spend(s.cost)) return false;
    await _repo.addOwnedPieceSkin(s.id);
    notifyListeners();
    return true;
  }

  Future<void> equipPieceSkin(PieceSkin s) async {
    if (!ownsPieceSkin(s)) return;
    await _repo.setEquippedPieceSkin(s.id);
    notifyListeners();
  }

  // ── Consumibles ─────────────────────────────────────────────────────
  int consumableCount(ShopConsumable c) => _repo.consumableCount(c.id);

  /// Cargas disponibles (lectura, sin consumir) para el ítem del [mode], hasta
  /// [cap]. Lo usa `GameScreen` para conocer las cargas iniciales extra antes de
  /// crear el `GameProvider`.
  int startingChargesAvailable(GameMode mode, {int cap = 3}) {
    for (final v in ShopConsumable.values) {
      if (v.mode == mode) {
        final n = _repo.consumableCount(v.id);
        return n > cap ? cap : n;
      }
    }
    return 0;
  }

  Future<bool> buyConsumable(ShopConsumable c) async {
    if (!await _repo.spend(c.cost)) return false;
    await _repo.addConsumable(c.id);
    notifyListeners();
    return true;
  }

  /// Consume las cargas extra guardadas para el ítem del [mode] (hasta [cap]) y
  /// devuelve cuántas aplicar como cargas iniciales adicionales. Se llama al
  /// iniciar la partida del modo correspondiente (plan §3.1).
  Future<int> takeStartingCharges(GameMode mode, {int cap = 3}) async {
    ShopConsumable? c;
    for (final v in ShopConsumable.values) {
      if (v.mode == mode) {
        c = v;
        break;
      }
    }
    if (c == null) return 0;
    final used = await _repo.consume(c.id, cap);
    if (used > 0) notifyListeners();
    return used;
  }
}
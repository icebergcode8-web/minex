import 'package:flutter_test/flutter_test.dart';
import 'package:minex/data/local/hive_service.dart';
import 'package:minex/data/repositories/economy_repository.dart';
import 'package:minex/domain/models/board_skin.dart';
import 'package:minex/domain/models/game_mode.dart';
import 'package:minex/domain/models/piece_skin.dart';
import 'package:minex/domain/models/shop_item.dart';
import 'package:minex/providers/economy_provider.dart';

/// Economía en memoria: evita depender de Hive.
class FakeEconomyRepository extends EconomyRepository {
  FakeEconomyRepository() : super(HiveService());

  int _coins = 0;
  int _earned = 0;
  final Set<String> _board = {BoardSkin.classic.id};
  final Set<String> _piece = {PieceSkin.classic.id};
  String _equipBoard = BoardSkin.classic.id;
  String _equipPiece = PieceSkin.classic.id;
  final Map<String, int> _consumables = {};

  @override
  int get coins => _coins;
  @override
  int get totalEarned => _earned;
  @override
  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    _coins += amount;
    _earned += amount;
  }

  @override
  Future<bool> spend(int cost) async {
    if (_coins < cost) return false;
    _coins -= cost;
    return true;
  }

  @override
  Set<String> get ownedBoardSkins => {..._board};
  @override
  Future<void> addOwnedBoardSkin(String id) async => _board.add(id);
  @override
  String get equippedBoardSkinId => _equipBoard;
  @override
  Future<void> setEquippedBoardSkin(String id) async => _equipBoard = id;

  @override
  Set<String> get ownedPieceSkins => {..._piece};
  @override
  Future<void> addOwnedPieceSkin(String id) async => _piece.add(id);
  @override
  String get equippedPieceSkinId => _equipPiece;
  @override
  Future<void> setEquippedPieceSkin(String id) async => _equipPiece = id;

  @override
  int consumableCount(String id) => _consumables[id] ?? 0;
  @override
  Future<void> addConsumable(String id, [int n = 1]) async =>
      _consumables[id] = consumableCount(id) + n;
  @override
  Future<int> consume(String id, int max) async {
    final have = consumableCount(id);
    final used = have < max ? have : max;
    _consumables[id] = have - used;
    return used;
  }
}

void main() {
  late EconomyProvider economy;

  setUp(() => economy = EconomyProvider(FakeEconomyRepository()));

  test('addCoins acumula saldo e histórico', () async {
    await economy.addCoins(50);
    expect(economy.coins, 50);
    expect(economy.totalEarned, 50);
    await economy.addCoins(-10); // ignora negativos
    expect(economy.coins, 50);
  });

  test('no se puede comprar una skin sin saldo', () async {
    await economy.addCoins(50);
    final ok = await economy.buyBoardSkin(BoardSkin.neon); // cuesta 150
    expect(ok, isFalse);
    expect(economy.ownsBoardSkin(BoardSkin.neon), isFalse);
    expect(economy.coins, 50);
  });

  test('comprar y equipar una skin de tablero', () async {
    await economy.addCoins(200);
    final ok = await economy.buyBoardSkin(BoardSkin.neon);
    expect(ok, isTrue);
    expect(economy.coins, 50); // 200 - 150
    expect(economy.ownsBoardSkin(BoardSkin.neon), isTrue);

    await economy.equipBoardSkin(BoardSkin.neon);
    expect(economy.equippedBoardSkin, BoardSkin.neon);
    // No se puede volver a comprar lo ya poseído.
    expect(await economy.buyBoardSkin(BoardSkin.neon), isFalse);
  });

  test('comprar consumibles y tomarlos como cargas iniciales', () async {
    await economy.addCoins(200);
    expect(await economy.buyConsumable(ShopConsumable.flashlight), isTrue);
    expect(await economy.buyConsumable(ShopConsumable.flashlight), isTrue);
    expect(economy.consumableCount(ShopConsumable.flashlight), 2);
    expect(economy.startingChargesAvailable(GameMode.fog), 2);

    final taken = await economy.takeStartingCharges(GameMode.fog);
    expect(taken, 2);
    expect(economy.consumableCount(ShopConsumable.flashlight), 0);
    // Otros modos sin consumible mapeado no dan cargas.
    expect(economy.startingChargesAvailable(GameMode.classic), 0);
  });
}
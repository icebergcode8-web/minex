import 'package:hive_ce_flutter/hive_flutter.dart';

/// Nombres de las cajas Hive (plan §6.2).
abstract final class HiveBoxes {
  static const settings = 'settingsBox';
  static const records = 'recordsBox';
  static const stats = 'statsBox';
  static const economy = 'economyBox';
  static const achievements = 'achievementsBox';
  static const daily = 'dailyBox';
  static const savegame = 'savegameBox';
}

/// Punto único de acceso a Hive (plan §6.3: la única capa —junto a los
/// repositorios— que toca Hive). Guarda todo como tipos primitivos / mapas
/// para evitar TypeAdapters generados y build_runner (plan §6.2).
class HiveService {
  Box? _settings;
  Box? _records;
  Box? _savegame;
  Box? _economy;
  Box? _achievements;
  Box? _daily;

  bool get isReady =>
      _settings != null &&
      _records != null &&
      _savegame != null &&
      _economy != null &&
      _achievements != null &&
      _daily != null;

  /// Inicializa Hive y abre las cajas necesarias. Idempotente.
  Future<void> init() async {
    if (isReady) return;
    await Hive.initFlutter();
    _settings = await Hive.openBox(HiveBoxes.settings);
    _records = await Hive.openBox(HiveBoxes.records);
    _savegame = await Hive.openBox(HiveBoxes.savegame);
    _economy = await Hive.openBox(HiveBoxes.economy);
    _achievements = await Hive.openBox(HiveBoxes.achievements);
    _daily = await Hive.openBox(HiveBoxes.daily);
  }

  Box get settings => _requireBox(_settings, HiveBoxes.settings);
  Box get records => _requireBox(_records, HiveBoxes.records);
  Box get savegame => _requireBox(_savegame, HiveBoxes.savegame);
  Box get economy => _requireBox(_economy, HiveBoxes.economy);
  Box get achievements => _requireBox(_achievements, HiveBoxes.achievements);
  Box get daily => _requireBox(_daily, HiveBoxes.daily);

  Box _requireBox(Box? box, String name) {
    if (box == null) {
      throw StateError('La caja "$name" no está abierta. Llama a init() antes.');
    }
    return box;
  }
}
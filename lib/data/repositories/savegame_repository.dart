import 'dart:convert';

import '../local/hive_service.dart';

/// Partida en curso serializada (plan §6.2/§6.3). Única capa que toca Hive para
/// el `savegameBox`. Guarda el estado de la run de Oleadas como JSON string a
/// nivel de **tablero exacto**: la progresión (oleada, vidas, puntaje, mejoras)
/// más el tablero completo en curso (celdas reveladas, banderas, minas,
/// modificador activo, minas con retardo ya inyectadas) — de modo que
/// "kill+reabrir restaura Oleadas" (§12) reanuda la partida tal cual estaba.
class SavegameRepository {
  SavegameRepository(this._hive);

  final HiveService _hive;

  static const _kWaves = 'waves';

  bool get hasWaves => _hive.savegame.containsKey(_kWaves);

  /// Estado guardado de la run de Oleadas, o `null` si no hay ninguno.
  Map<String, dynamic>? loadWaves() {
    final raw = _hive.savegame.get(_kWaves) as String?;
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null; // dato corrupto: se ignora en vez de romper
    }
  }

  Future<void> saveWaves(Map<String, dynamic> state) =>
      _hive.savegame.put(_kWaves, jsonEncode(state));

  Future<void> clearWaves() => _hive.savegame.delete(_kWaves);
}
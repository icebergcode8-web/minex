import '../../core/constants/difficulty.dart';
import '../local/hive_service.dart';

/// Récords locales del modo clásico por dificultad (plan §2.1: mejor tiempo,
/// winrate, racha). Persistidos en `recordsBox`.
class RecordsRepository {
  RecordsRepository(this._hive);

  final HiveService _hive;

  String _bestTimeKey(Difficulty d) => 'classic_bestTimeMs_${d.name}';
  String _winsKey(Difficulty d) => 'classic_wins_${d.name}';
  String _playedKey(Difficulty d) => 'classic_played_${d.name}';

  /// Mejor tiempo en milisegundos, o `null` si no hay récord.
  int? bestTimeMs(Difficulty d) => _hive.records.get(_bestTimeKey(d));

  int wins(Difficulty d) => _hive.records.get(_winsKey(d), defaultValue: 0);
  int played(Difficulty d) => _hive.records.get(_playedKey(d), defaultValue: 0);

  /// Registra una partida terminada. Devuelve `true` si es nuevo récord de
  /// tiempo (solo aplica a victorias).
  Future<bool> recordGame({
    required Difficulty difficulty,
    required bool won,
    required Duration elapsed,
  }) async {
    await _hive.records
        .put(_playedKey(difficulty), played(difficulty) + 1);

    if (!won) return false;

    await _hive.records.put(_winsKey(difficulty), wins(difficulty) + 1);

    final ms = elapsed.inMilliseconds;
    final prev = bestTimeMs(difficulty);
    if (prev == null || ms < prev) {
      await _hive.records.put(_bestTimeKey(difficulty), ms);
      return true;
    }
    return false;
  }
}

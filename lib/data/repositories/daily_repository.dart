import '../local/hive_service.dart';

/// Historial del Reto Diario y racha (plan §2.7). Única capa que toca
/// `dailyBox`. Solo almacena primitivos; el cálculo de racha/consecutividad
/// vive en `DailyProvider` con `DailyEngine` (puro).
class DailyRepository {
  DailyRepository(this._hive);

  final HiveService _hive;

  static const _kLastKey = 'lastDayKey'; // yyyyMMdd del último completado
  static const _kLastNum = 'lastDayNumber'; // ordinal para consecutividad
  static const _kStreak = 'currentStreak';
  static const _kLongest = 'longestStreak';
  static const _kCount = 'completedCount';

  int? get lastDayKey => _hive.daily.get(_kLastKey) as int?;
  int? get lastDayNumber => _hive.daily.get(_kLastNum) as int?;
  int get currentStreak => _hive.daily.get(_kStreak, defaultValue: 0);
  int get longestStreak => _hive.daily.get(_kLongest, defaultValue: 0);
  int get completedCount => _hive.daily.get(_kCount, defaultValue: 0);

  /// Persiste el estado tras completar un reto (los valores los calcula el
  /// provider con `DailyEngine`).
  Future<void> save({
    required int dayKey,
    required int dayNumber,
    required int currentStreak,
    required int longestStreak,
    required int completedCount,
  }) async {
    await _hive.daily.put(_kLastKey, dayKey);
    await _hive.daily.put(_kLastNum, dayNumber);
    await _hive.daily.put(_kStreak, currentStreak);
    await _hive.daily.put(_kLongest, longestStreak);
    await _hive.daily.put(_kCount, completedCount);
  }
}
import 'package:flutter/foundation.dart';

import '../data/repositories/daily_repository.dart';
import '../domain/engine/daily_engine.dart';

/// Estado global del Reto Diario y racha (plan §2.7). Orquesta [DailyRepository]
/// con [DailyEngine] (puro). El reloj es inyectable para tests.
///
// ignore_for_file: prefer_initializing_formals
class DailyProvider extends ChangeNotifier {
  DailyProvider({
    required DailyRepository repo,
    DailyEngine engine = const DailyEngine(),
    DateTime Function() clock = DateTime.now,
  })  : _repo = repo,
        _engine = engine,
        _clock = clock;

  final DailyRepository _repo;
  final DailyEngine _engine;
  final DateTime Function() _clock;

  DateTime get today => _clock();
  DailyEngine get engine => _engine;

  DailySpec get todaySpec => _engine.specFor(today);
  int get todaySeed => _engine.seedFor(today);

  bool get isCompletedToday => _repo.lastDayKey == _engine.dayKey(today);

  int get currentStreak => _repo.currentStreak;
  int get longestStreak => _repo.longestStreak;
  int get completedCount => _repo.completedCount;

  /// Marca el reto de hoy como completado y devuelve la nueva racha (para
  /// calcular la recompensa con `EconomyEngine.streakReward`). Devuelve 0 si ya
  /// estaba completado hoy (sin recompensa doble).
  Future<int> markCompleted() async {
    if (isCompletedToday) return 0;
    final now = today;
    final todayNum = _engine.dayNumber(now);
    final prevNum = _repo.lastDayNumber;

    final newStreak =
        (prevNum != null && todayNum - prevNum == 1) ? _repo.currentStreak + 1 : 1;
    final newLongest =
        newStreak > _repo.longestStreak ? newStreak : _repo.longestStreak;

    await _repo.save(
      dayKey: _engine.dayKey(now),
      dayNumber: todayNum,
      currentStreak: newStreak,
      longestStreak: newLongest,
      completedCount: _repo.completedCount + 1,
    );
    notifyListeners();
    return newStreak;
  }
}
import 'package:flutter_test/flutter_test.dart';
import 'package:minex/data/local/hive_service.dart';
import 'package:minex/data/repositories/daily_repository.dart';
import 'package:minex/providers/daily_provider.dart';

/// Reto diario en memoria.
class FakeDailyRepository extends DailyRepository {
  FakeDailyRepository() : super(HiveService());
  int? _key;
  int? _num;
  int _streak = 0;
  int _longest = 0;
  int _count = 0;

  @override
  int? get lastDayKey => _key;
  @override
  int? get lastDayNumber => _num;
  @override
  int get currentStreak => _streak;
  @override
  int get longestStreak => _longest;
  @override
  int get completedCount => _count;

  @override
  Future<void> save({
    required int dayKey,
    required int dayNumber,
    required int currentStreak,
    required int longestStreak,
    required int completedCount,
  }) async {
    _key = dayKey;
    _num = dayNumber;
    _streak = currentStreak;
    _longest = longestStreak;
    _count = completedCount;
  }
}

void main() {
  test('racha: días consecutivos suben, saltarse un día la reinicia', () async {
    var now = DateTime(2024, 1, 1);
    final daily = DailyProvider(repo: FakeDailyRepository(), clock: () => now);

    expect(daily.isCompletedToday, isFalse);
    expect(await daily.markCompleted(), 1);
    expect(daily.currentStreak, 1);
    expect(daily.completedCount, 1);
    expect(daily.isCompletedToday, isTrue);

    // Mismo día: no da recompensa ni duplica.
    expect(await daily.markCompleted(), 0);
    expect(daily.completedCount, 1);

    // Día siguiente: racha 2.
    now = DateTime(2024, 1, 2);
    expect(await daily.markCompleted(), 2);
    expect(daily.currentStreak, 2);
    expect(daily.longestStreak, 2);

    // Salta el día 3, juega el 4: racha se reinicia a 1 (longest se mantiene).
    now = DateTime(2024, 1, 4);
    expect(await daily.markCompleted(), 1);
    expect(daily.currentStreak, 1);
    expect(daily.longestStreak, 2);
    expect(daily.completedCount, 3);
  });

  test('el spec de hoy corresponde al reloj inyectado', () {
    final daily = DailyProvider(
      repo: FakeDailyRepository(),
      clock: () => DateTime(2024, 1, 5), // viernes
    );
    expect(daily.todaySeed, 20240105);
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:minex/domain/engine/achievements_catalog.dart';
import 'package:minex/domain/models/achievement.dart';

void main() {
  const catalog = AchievementsCatalog();

  test('el catálogo tiene ~30 logros con ids únicos', () {
    expect(catalog.all.length, greaterThanOrEqualTo(30));
    final ids = catalog.all.map((a) => a.id).toSet();
    expect(ids.length, catalog.all.length); // sin ids duplicados
  });

  test('desbloquea los logros cuyo predicado se cumple', () {
    const ctx = AchievementContext(totalWins: 1, totalGames: 1, winsEasy: 1);
    final ids = catalog.evaluate(ctx, {});
    expect(ids, contains('first_win'));
    expect(ids, contains('win_easy'));
    expect(ids, isNot(contains('win_expert')));
  });

  test('no vuelve a desbloquear los ya desbloqueados', () {
    const ctx = AchievementContext(totalWins: 1, winsEasy: 1);
    final ids = catalog.evaluate(ctx, {'first_win'});
    expect(ids, isNot(contains('first_win')));
    expect(ids, contains('win_easy'));
  });

  test('la mejor oleada desbloquea los hitos acumulativos', () {
    const ctx = AchievementContext(bestWave: 10);
    final ids = catalog.evaluate(ctx, {});
    expect(ids, containsAll(<String>['wave_5', 'wave_10']));
    expect(ids, isNot(contains('wave_20')));
  });

  test('byId recupera un logro con su recompensa', () {
    final a = catalog.byId('streak_7');
    expect(a, isNotNull);
    expect(a!.coins, greaterThan(0));
    expect(a.name('es'), isNotEmpty);
    expect(a.name('en'), isNotEmpty);
  });
}
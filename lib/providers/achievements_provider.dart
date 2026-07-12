import 'package:flutter/foundation.dart';

import '../core/constants/difficulty.dart';
import '../data/repositories/achievements_repository.dart';
import '../data/repositories/daily_repository.dart';
import '../data/repositories/economy_repository.dart';
import '../data/repositories/records_repository.dart';
import '../domain/engine/achievements_catalog.dart';
import '../domain/models/achievement.dart';
import '../domain/models/game_outcome.dart';

/// Logros recién desbloueados en una evaluación, con las monedas que otorgan.
class UnlockResult {
  const UnlockResult(this.achievements);
  final List<Achievement> achievements;

  bool get isEmpty => achievements.isEmpty;
  int get coins => achievements.fold(0, (s, a) => s + a.coins);
}

/// Estado global de logros (plan §3.2). Ensambla el [AchievementContext] desde
/// los repositorios y evalúa el catálogo puro. No otorga monedas directamente:
/// devuelve los logros nuevos (con sus monedas) para que el orquestador las
/// sume vía [EconomyProvider], manteniendo el flujo de notificaciones limpio.
///
// Lista de inicialización deliberada (params públicos → campos privados).
// ignore_for_file: prefer_initializing_formals
class AchievementsProvider extends ChangeNotifier {
  AchievementsProvider({
    required AchievementsRepository repo,
    required RecordsRepository records,
    required EconomyRepository economy,
    required DailyRepository daily,
    AchievementsCatalog catalog = const AchievementsCatalog(),
  })  : _repo = repo,
        _records = records,
        _economy = economy,
        _daily = daily,
        _catalog = catalog;

  final AchievementsRepository _repo;
  final RecordsRepository _records;
  final EconomyRepository _economy;
  final DailyRepository _daily;
  final AchievementsCatalog _catalog;

  List<Achievement> get all => _catalog.all;
  Set<String> get unlocked => _repo.unlocked;
  bool isUnlocked(String id) => _repo.unlocked.contains(id);
  int get unlockedCount => _repo.unlocked.length;
  int get total => _catalog.all.length;

  AchievementContext _buildContext() => AchievementContext(
        totalWins: _repo.totalWins,
        totalGames: _repo.totalGames,
        winsEasy: _repo.winsEasy,
        winsMedium: _repo.winsMedium,
        winsHard: _repo.winsHard,
        winsExpert: _repo.winsExpert,
        bestTimeEasyMs: _records.bestTimeMs(Difficulty.easy),
        fogWins: _repo.fogWins,
        liarWins: _repo.liarWins,
        blitzBestScore: _records.blitzBestScore,
        blitzBestBoards: _repo.blitzBestBoards,
        bestWave: _repo.bestWave,
        wavesBestScore: _records.wavesBestScore,
        flaglessExpertWin: _repo.flaglessExpertWin,
        dailyCompleted: _daily.completedCount,
        longestStreak: _daily.longestStreak,
        totalCoinsEarned: _economy.totalEarned,
        ownedBoardSkins: _economy.ownedBoardSkins.length,
        ownedPieceSkins: _economy.ownedPieceSkins.length,
      );

  /// Actualiza contadores con [o] y desbloquea los logros que ahora se cumplen.
  Future<UnlockResult> registerOutcome(GameOutcome o) async {
    await _repo.recordOutcome(o);
    return _evaluateAndUnlock();
  }

  /// Reevalúa sin un outcome (tras comprar skins, completar racha, etc.).
  Future<UnlockResult> reevaluate() => _evaluateAndUnlock();

  Future<UnlockResult> _evaluateAndUnlock() async {
    final ctx = _buildContext();
    final ids = _catalog.evaluate(ctx, _repo.unlocked);
    final unlocked = <Achievement>[];
    for (final id in ids) {
      await _repo.unlock(id);
      final a = _catalog.byId(id);
      if (a != null) unlocked.add(a);
    }
    if (unlocked.isNotEmpty) notifyListeners();
    return UnlockResult(unlocked);
  }
}
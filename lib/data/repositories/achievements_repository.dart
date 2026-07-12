import '../../core/constants/difficulty.dart';
import '../../domain/models/game_mode.dart';
import '../../domain/models/game_outcome.dart';
import '../local/hive_service.dart';

/// Estado de logros (plan §3.2): conjunto de desbloqueados + contadores
/// acumulados que no viven en otros repos (victorias por modo, mejor oleada,
/// etc.). Única capa que toca `achievementsBox`. Solo cuenta/almacena; la
/// evaluación de qué logro se cumple vive en `AchievementsCatalog` (puro).
class AchievementsRepository {
  AchievementsRepository(this._hive);

  final HiveService _hive;

  static const _kUnlocked = 'unlocked';

  // ── Desbloqueados ───────────────────────────────────────────────────
  Set<String> get unlocked {
    final list = (_hive.achievements.get(_kUnlocked) as List?)?.cast<String>();
    return {...?list};
  }

  Future<void> unlock(String id) async {
    final set = unlocked..add(id);
    await _hive.achievements.put(_kUnlocked, set.toList());
  }

  // ── Contadores acumulados ───────────────────────────────────────────
  int get totalWins => _get('totalWins');
  int get totalGames => _get('totalGames');
  int get winsEasy => _get('winsEasy');
  int get winsMedium => _get('winsMedium');
  int get winsHard => _get('winsHard');
  int get winsExpert => _get('winsExpert');
  int get fogWins => _get('fogWins');
  int get liarWins => _get('liarWins');
  int get bestWave => _get('bestWave');
  int get blitzBestBoards => _get('blitzBestBoards');
  bool get flaglessExpertWin =>
      _hive.achievements.get('flaglessExpertWin', defaultValue: false);

  int _get(String key) => _hive.achievements.get(key, defaultValue: 0);
  Future<void> _put(String key, int value) =>
      _hive.achievements.put(key, value);

  /// Actualiza los contadores acumulados con el resultado de una partida
  /// (bookkeeping, igual que `RecordsRepository.recordGame`).
  Future<void> recordOutcome(GameOutcome o) async {
    await _put('totalGames', totalGames + 1);
    if (o.won) {
      await _put('totalWins', totalWins + 1);
      switch (o.difficulty) {
        case Difficulty.easy:
          await _put('winsEasy', winsEasy + 1);
        case Difficulty.medium:
          await _put('winsMedium', winsMedium + 1);
        case Difficulty.hard:
          await _put('winsHard', winsHard + 1);
        case Difficulty.expert:
          await _put('winsExpert', winsExpert + 1);
        case Difficulty.custom:
          break;
      }
      if (o.mode == GameMode.fog) await _put('fogWins', fogWins + 1);
      if (o.mode == GameMode.liar) await _put('liarWins', liarWins + 1);
      if (o.mode == GameMode.classic &&
          o.difficulty == Difficulty.expert &&
          !o.usedFlags) {
        await _hive.achievements.put('flaglessExpertWin', true);
      }
    }
    if (o.wavesReached > bestWave) await _put('bestWave', o.wavesReached);
    if (o.blitzBoards > blitzBestBoards) {
      await _put('blitzBestBoards', o.blitzBoards);
    }
  }
}
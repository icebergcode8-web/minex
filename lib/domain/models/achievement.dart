/// Datos acumulados del jugador contra los que se evalúan los logros (plan
/// §3.2). Objeto puro que ensambla el `AchievementsProvider` a partir de los
/// repositorios; los predicados del catálogo solo lo leen.
class AchievementContext {
  const AchievementContext({
    this.totalWins = 0,
    this.totalGames = 0,
    this.winsEasy = 0,
    this.winsMedium = 0,
    this.winsHard = 0,
    this.winsExpert = 0,
    this.bestTimeEasyMs,
    this.fogWins = 0,
    this.liarWins = 0,
    this.blitzBestScore = 0,
    this.blitzBestBoards = 0,
    this.bestWave = 0,
    this.wavesBestScore = 0,
    this.flaglessExpertWin = false,
    this.dailyCompleted = 0,
    this.longestStreak = 0,
    this.totalCoinsEarned = 0,
    this.ownedBoardSkins = 1,
    this.ownedPieceSkins = 1,
  });

  final int totalWins;
  final int totalGames;
  final int winsEasy;
  final int winsMedium;
  final int winsHard;
  final int winsExpert;
  final int? bestTimeEasyMs;
  final int fogWins;
  final int liarWins;
  final int blitzBestScore;
  final int blitzBestBoards;
  final int bestWave;
  final int wavesBestScore;
  final bool flaglessExpertWin;
  final int dailyCompleted;
  final int longestStreak;
  final int totalCoinsEarned;
  final int ownedBoardSkins;
  final int ownedPieceSkins;
}

/// Definición de un logro (plan §3.2). El [predicate] es puro: dado un
/// [AchievementContext] decide si está desbloqueado. Otorga [coins] al lograrse.
class Achievement {
  const Achievement({
    required this.id,
    required this.emoji,
    required this.coins,
    required this.predicate,
    required this.name,
    required this.description,
  });

  final String id;
  final String emoji;
  final int coins;
  final bool Function(AchievementContext ctx) predicate;

  /// Nombre y descripción localizados (locale 'es' por defecto, 'en').
  final String Function(String locale) name;
  final String Function(String locale) description;
}
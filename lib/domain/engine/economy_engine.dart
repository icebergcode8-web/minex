import '../../core/constants/difficulty.dart';
import '../models/game_mode.dart';
import '../models/game_outcome.dart';

/// Cálculo puro de recompensas de monedas (plan §3.2). Sin Flutter ni Hive:
/// dado un [GameOutcome] decide cuántas monedas otorgar. Determinista y
/// testeable. El Reto Diario usa además [streakReward] por su racha.
class EconomyEngine {
  const EconomyEngine();

  /// Monedas base por victoria en el clásico, según dificultad (plan §2.1).
  int _classicBase(Difficulty d) => switch (d) {
        Difficulty.easy => 10,
        Difficulty.medium => 20,
        Difficulty.hard => 40,
        Difficulty.expert => 70,
        Difficulty.custom => 15,
      };

  /// Monedas ganadas por una partida terminada.
  ///
  /// - Clásico: base por dificultad (solo al ganar).
  /// - Niebla: ×1.5 sobre el clásico (plan §2.2).
  /// - Mentiroso: ×2 (plan §2.4).
  /// - Blitz: por tableros resueltos + fracción del puntaje (siempre que puntúe).
  /// - Oleadas: por oleadas alcanzadas (aunque termine en derrota).
  /// - El Reto Diario duplica el total (plan §2.7) — la racha se suma aparte.
  int coinsForOutcome(GameOutcome o) {
    var coins = switch (o.mode) {
      GameMode.classic => o.won ? _classicBase(o.difficulty) : 0,
      GameMode.fog => o.won ? (_classicBase(o.difficulty) * 1.5).round() : 0,
      GameMode.liar => o.won ? _classicBase(o.difficulty) * 2 : 0,
      GameMode.blitz => o.blitzBoards * 8 + o.blitzScore ~/ 20,
      GameMode.waves => o.wavesReached * 5,
      GameMode.tower => o.won ? _classicBase(o.difficulty) : 0,
      GameMode.daily => 0, // el Reto usa el modo real; nunca llega como 'daily'
    };
    if (o.isDaily) coins *= 2;
    return coins;
  }

  /// Recompensa por completar el Reto Diario en racha (plan §2.7): crece con los
  /// días consecutivos, con un cofre grande al 7º día y bonus semanal.
  ///
  /// [consecutiveDays] es el número de días seguidos ya completados (1 = primer
  /// día de la racha).
  int streakReward(int consecutiveDays) {
    if (consecutiveDays <= 0) return 0;
    // Día 7, 14, 21… → cofre grande.
    if (consecutiveDays % 7 == 0) return 100;
    // Escala suave: 10, 15, 20, 25, 30, 35 dentro de la semana.
    final withinWeek = ((consecutiveDays - 1) % 7) + 1;
    return 5 + withinWeek * 5;
  }
}
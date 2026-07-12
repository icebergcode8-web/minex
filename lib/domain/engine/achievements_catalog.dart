import '../models/achievement.dart';

/// Catálogo puro de logros (plan §3.2, ~30). Cada logro tiene un predicado
/// determinista sobre un [AchievementContext]. Sin Flutter ni Hive: el
/// `AchievementsProvider` ensambla el contexto y evalúa con [evaluate].
class AchievementsCatalog {
  const AchievementsCatalog();

  List<Achievement> get all => _all;

  /// Ids de logros cuyo predicado se cumple para [ctx] pero que aún no están en
  /// [unlocked]. El provider persiste el desbloqueo y otorga las monedas.
  List<String> evaluate(AchievementContext ctx, Set<String> unlocked) => [
        for (final a in _all)
          if (!unlocked.contains(a.id) && a.predicate(ctx)) a.id,
      ];

  Achievement? byId(String id) {
    for (final a in _all) {
      if (a.id == id) return a;
    }
    return null;
  }
}

/// Azúcar para declarar un logro con textos es/en.
Achievement _a(
  String id,
  String emoji,
  int coins,
  String nameEs,
  String nameEn,
  String descEs,
  String descEn,
  bool Function(AchievementContext) predicate,
) =>
    Achievement(
      id: id,
      emoji: emoji,
      coins: coins,
      predicate: predicate,
      name: (l) => l == 'en' ? nameEn : nameEs,
      description: (l) => l == 'en' ? descEn : descEs,
    );

final List<Achievement> _all = [
  // ── Clásico ──────────────────────────────────────────────────────────
  _a('first_win', '🎉', 20, 'Primera victoria', 'First win',
      'Gana tu primera partida.', 'Win your first game.',
      (c) => c.totalWins >= 1),
  _a('win_easy', '🟢', 10, 'Fácil despejado', 'Easy cleared',
      'Gana en dificultad Fácil.', 'Win on Easy.', (c) => c.winsEasy >= 1),
  _a('win_medium', '🟡', 20, 'Medio despejado', 'Medium cleared',
      'Gana en dificultad Medio.', 'Win on Medium.', (c) => c.winsMedium >= 1),
  _a('win_hard', '🟠', 40, 'Difícil despejado', 'Hard cleared',
      'Gana en dificultad Difícil.', 'Win on Hard.', (c) => c.winsHard >= 1),
  _a('win_expert', '🔴', 80, 'Experto despejado', 'Expert cleared',
      'Gana en dificultad Experto.', 'Win on Expert.', (c) => c.winsExpert >= 1),
  _a('expert_no_flags', '🏴', 150, 'Experto sin banderas',
      'Expert, no flags', 'Gana en Experto sin poner una sola bandera.',
      'Win on Expert without placing a flag.', (c) => c.flaglessExpertWin),
  _a('wins_10', '🔟', 40, '10 victorias', '10 wins',
      'Acumula 10 victorias.', 'Reach 10 wins.', (c) => c.totalWins >= 10),
  _a('wins_50', '⭐', 100, '50 victorias', '50 wins',
      'Acumula 50 victorias.', 'Reach 50 wins.', (c) => c.totalWins >= 50),
  _a('wins_100', '👑', 200, 'Centurión', 'Centurion',
      'Acumula 100 victorias.', 'Reach 100 wins.', (c) => c.totalWins >= 100),
  _a('speed_easy', '⚡', 50, 'Rayo', 'Lightning',
      'Gana en Fácil en menos de 20s.', 'Win Easy under 20s.',
      (c) => c.bestTimeEasyMs != null && c.bestTimeEasyMs! <= 20000),
  _a('games_100', '🎮', 60, 'Veterano', 'Veteran',
      'Juega 100 partidas.', 'Play 100 games.', (c) => c.totalGames >= 100),

  // ── Niebla ───────────────────────────────────────────────────────────
  _a('fog_first', '🌫️', 25, 'Entre la niebla', 'Into the fog',
      'Gana una partida en modo Niebla.', 'Win a Fog game.',
      (c) => c.fogWins >= 1),
  _a('fog_10', '🌁', 80, 'Ojo de halcón', 'Hawk eye',
      'Gana 10 partidas en Niebla.', 'Win 10 Fog games.',
      (c) => c.fogWins >= 10),

  // ── Blitz ────────────────────────────────────────────────────────────
  _a('blitz_100', '💯', 40, 'Blitz 100', 'Blitz 100',
      'Consigue 100 puntos en Blitz.', 'Score 100 in Blitz.',
      (c) => c.blitzBestScore >= 100),
  _a('blitz_300', '🚀', 100, 'Blitz 300', 'Blitz 300',
      'Consigue 300 puntos en Blitz.', 'Score 300 in Blitz.',
      (c) => c.blitzBestScore >= 300),
  _a('blitz_boards_5', '🔥', 60, 'Cadena de tableros', 'Board chain',
      'Resuelve 5 tableros en una partida Blitz.', 'Clear 5 boards in one Blitz.',
      (c) => c.blitzBestBoards >= 5),

  // ── Mentiroso ────────────────────────────────────────────────────────
  _a('liar_first', '🃏', 30, 'Detector de mentiras', 'Lie detector',
      'Gana una partida en modo Mentiroso.', 'Win a Liar game.',
      (c) => c.liarWins >= 1),
  _a('liar_10', '🕵️', 90, 'La verdad revelada', 'The truth revealed',
      'Gana 10 partidas en Mentiroso.', 'Win 10 Liar games.',
      (c) => c.liarWins >= 10),

  // ── Oleadas ──────────────────────────────────────────────────────────
  _a('wave_5', '🌊', 40, 'Rompiente', 'Breaker',
      'Alcanza la oleada 5.', 'Reach wave 5.', (c) => c.bestWave >= 5),
  _a('wave_10', '🌊', 100, 'Oleada 10', 'Wave 10',
      'Alcanza la oleada 10.', 'Reach wave 10.', (c) => c.bestWave >= 10),
  _a('wave_20', '🐋', 250, 'Superviviente', 'Survivor',
      'Alcanza la oleada 20.', 'Reach wave 20.', (c) => c.bestWave >= 20),
  _a('waves_score_500', '🏅', 80, 'Marea alta', 'High tide',
      'Suma 500 puntos en Oleadas.', 'Score 500 in Waves.',
      (c) => c.wavesBestScore >= 500),

  // ── Reto Diario / racha ──────────────────────────────────────────────
  _a('daily_first', '📅', 20, 'Primer reto', 'First challenge',
      'Completa un Reto Diario.', 'Complete a Daily Challenge.',
      (c) => c.dailyCompleted >= 1),
  _a('streak_3', '🔥', 40, 'Racha de 3', '3-day streak',
      'Completa 3 retos seguidos.', 'Complete 3 challenges in a row.',
      (c) => c.longestStreak >= 3),
  _a('streak_7', '🔥', 120, 'Racha de 7 días', '7-day streak',
      'Completa 7 retos seguidos.', 'Complete 7 challenges in a row.',
      (c) => c.longestStreak >= 7),
  _a('streak_30', '💎', 400, 'Racha de 30 días', '30-day streak',
      'Completa 30 retos seguidos.', 'Complete 30 challenges in a row.',
      (c) => c.longestStreak >= 30),

  // ── Economía / colección ─────────────────────────────────────────────
  _a('coins_500', '🪙', 50, 'Ahorrador', 'Saver',
      'Gana 500 monedas en total.', 'Earn 500 coins total.',
      (c) => c.totalCoinsEarned >= 500),
  _a('skin_first', '🎨', 30, 'Buen gusto', 'Good taste',
      'Compra tu primera skin.', 'Buy your first skin.',
      (c) => c.ownedBoardSkins + c.ownedPieceSkins >= 3),
  _a('all_board_skins', '🖼️', 200, 'Coleccionista', 'Collector',
      'Desbloquea todas las skins de tablero.', 'Unlock all board skins.',
      (c) => c.ownedBoardSkins >= 6),
  _a('all_piece_skins', '✨', 150, 'Esteta', 'Aesthete',
      'Desbloquea todas las skins de piezas.', 'Unlock all piece skins.',
      (c) => c.ownedPieceSkins >= 4),
];
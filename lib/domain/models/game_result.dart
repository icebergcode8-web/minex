import 'game_mode.dart';

/// Resultado de una partida terminada (plan §6.4 / §4.1 ResultOverlay).
///
/// Objeto puro que el engine/provider produce al ganar o perder, y que los
/// repositorios usan para actualizar récords, stats y economía.
class GameResult {
  const GameResult({
    required this.mode,
    required this.won,
    required this.elapsed,
    this.score = 0,
    this.coinsEarned = 0,
    this.isNewRecord = false,
  });

  final GameMode mode;
  final bool won;

  /// Tiempo transcurrido de la partida.
  final Duration elapsed;

  /// Puntaje (modos con score: Blitz, Oleadas, etc.). 0 en clásico puro.
  final int score;

  /// Monedas ganadas (antes de multiplicadores por rewarded).
  final int coinsEarned;

  /// `true` si supera el mejor récord local de su modo/dificultad.
  final bool isNewRecord;
}

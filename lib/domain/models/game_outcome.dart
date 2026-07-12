import '../../core/constants/difficulty.dart';
import 'game_mode.dart';

/// Instantánea inmutable del final de una partida (plan §3.2/§8.4). El
/// `GameProvider` la emite al terminar; la economía y los logros la consumen
/// para otorgar monedas y desbloquear logros. No contiene lógica: solo datos.
class GameOutcome {
  const GameOutcome({
    required this.mode,
    required this.difficulty,
    required this.won,
    required this.elapsed,
    this.timeUp = false,
    this.usedFlags = false,
    this.blitzScore = 0,
    this.blitzBoards = 0,
    this.wavesReached = 0,
    this.wavesScore = 0,
    this.isDaily = false,
  });

  final GameMode mode;
  final Difficulty difficulty;
  final bool won;
  final Duration elapsed;

  /// Blitz: la partida terminó por tiempo (no por mina).
  final bool timeUp;

  /// `true` si el jugador usó al menos una bandera (para logros "sin banderas").
  final bool usedFlags;

  final int blitzScore;
  final int blitzBoards;
  final int wavesReached;
  final int wavesScore;

  /// La partida forma parte del Reto Diario (plan §2.7).
  final bool isDaily;

  /// Se considera "completada con éxito" para el Reto Diario / rachas: victoria
  /// en modos normales, fin por tiempo en Blitz, o haber jugado en Oleadas.
  bool get isSuccess =>
      won ||
      (mode == GameMode.blitz && timeUp) ||
      (mode == GameMode.waves && wavesReached >= 1);
}
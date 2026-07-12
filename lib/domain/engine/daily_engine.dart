import '../../core/constants/difficulty.dart';
import '../models/game_config.dart';
import '../models/game_mode.dart';

/// Configuración de un Reto Diario para una fecha (plan §2.7). Puro.
class DailySpec {
  const DailySpec({
    required this.config,
    required this.difficulty,
    required this.mode,
  });

  /// Config lista para jugar (con seed determinista de la fecha).
  final GameConfig config;

  /// Dificultad asociada (para récords/etiquetas); `easy` como marcador en modos
  /// sin dificultad (Blitz/Oleadas).
  final Difficulty difficulty;

  /// Modo del día (para la tarjeta). Puede ser [GameMode.tower], que hasta la
  /// Fase 6 se juega como clásico experto.
  final GameMode mode;
}

/// Generación determinista del Reto Diario (plan §2.7). 100% offline: todo
/// depende solo de la fecha local. Sin Flutter ni Hive.
class DailyEngine {
  const DailyEngine();

  /// Seed = `yyyyMMdd` como entero (plan §2.7). Igual a
  /// `int.parse(DateFormat('yyyyMMdd').format(date))`.
  int seedFor(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

  /// Clave de día para persistir/comparar (idéntica al seed).
  int dayKey(DateTime date) => seedFor(date);

  /// Número ordinal de día (días desde una época fija) para comparar
  /// consecutividad sin líos de zona horaria.
  int dayNumber(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day)
          .difference(DateTime.utc(2000))
          .inDays;

  /// `true` si [today] es exactamente el día siguiente a [previous].
  bool isNextDay(DateTime previous, DateTime today) =>
      dayNumber(today) - dayNumber(previous) == 1;

  /// `true` si ambas fechas son el mismo día.
  bool isSameDay(DateTime a, DateTime b) => dayNumber(a) == dayNumber(b);

  /// Modo del día por rotación semanal (plan §2.7). El domingo (3D) se juega
  /// como clásico experto hasta la Fase 6.
  GameMode modeFor(DateTime date) => switch (date.weekday) {
        DateTime.monday => GameMode.classic,
        DateTime.tuesday => GameMode.fog,
        DateTime.wednesday => GameMode.blitz,
        DateTime.thursday => GameMode.liar,
        DateTime.friday => GameMode.classic, // "clásico difícil"
        DateTime.saturday => GameMode.waves,
        _ => GameMode.tower, // domingo
      };

  /// Construye el reto jugable de la fecha con seed determinista.
  DailySpec specFor(DateTime date) {
    final seed = seedFor(date);
    final mode = modeFor(date);
    return switch (mode) {
      GameMode.classic => DailySpec(
          // viernes: difícil; lunes: medio.
          config: classicConfig(
            date.weekday == DateTime.friday
                ? Difficulty.hard
                : Difficulty.medium,
            seed: seed,
          ),
          difficulty: date.weekday == DateTime.friday
              ? Difficulty.hard
              : Difficulty.medium,
          mode: GameMode.classic,
        ),
      GameMode.fog => DailySpec(
          config: fogConfig(Difficulty.medium, seed: seed),
          difficulty: Difficulty.medium,
          mode: GameMode.fog,
        ),
      GameMode.blitz => DailySpec(
          config: blitzConfig(seed: seed),
          difficulty: Difficulty.easy,
          mode: GameMode.blitz,
        ),
      GameMode.liar => DailySpec(
          config: liarConfig(Difficulty.medium, seed: seed),
          difficulty: Difficulty.medium,
          mode: GameMode.liar,
        ),
      GameMode.waves => DailySpec(
          config: wavesConfig(),
          difficulty: Difficulty.easy,
          mode: GameMode.waves,
        ),
      // Torre (domingo): fallback a clásico experto hasta la Fase 6.
      GameMode.tower || GameMode.daily => DailySpec(
          config: classicConfig(Difficulty.expert, seed: seed),
          difficulty: Difficulty.expert,
          mode: GameMode.tower,
        ),
    };
  }
}
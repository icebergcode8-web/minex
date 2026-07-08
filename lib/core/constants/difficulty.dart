import '../../domain/models/game_config.dart';
import '../../domain/models/game_mode.dart';

/// Dificultades del modo clásico (plan §2.1).
enum Difficulty { easy, medium, hard, expert, custom }

/// Preset de tamaño/minas para una dificultad.
class DifficultyPreset {
  const DifficultyPreset({
    required this.rows,
    required this.cols,
    required this.mines,
    this.lives = 1,
  });

  final int rows;
  final int cols;
  final int mines;
  final int lives;

  double get density => mines / (rows * cols);
}

/// Presets fijos del plan §2.1. `custom` no tiene preset (lo define el usuario).
const Map<Difficulty, DifficultyPreset> kDifficultyPresets = {
  Difficulty.easy: DifficultyPreset(rows: 9, cols: 9, mines: 10),
  Difficulty.medium: DifficultyPreset(rows: 14, cols: 12, mines: 28),
  Difficulty.hard: DifficultyPreset(rows: 20, cols: 16, mines: 64),
  Difficulty.expert: DifficultyPreset(rows: 26, cols: 20, mines: 115),
};

/// Límites del tablero personalizado (plan §2.1): 5×5 a 30×40, máx 30% minas.
const int kCustomMinSide = 5;
const int kCustomMaxRows = 40;
const int kCustomMaxCols = 30;
const double kCustomMaxDensity = 0.30;

/// Construye un [GameConfig] clásico a partir de una dificultad con preset.
///
/// Para [Difficulty.custom] usar [classicCustomConfig].
GameConfig classicConfig(Difficulty difficulty, {int? seed}) {
  assert(difficulty != Difficulty.custom,
      'Usa classicCustomConfig para dificultad personalizada');
  final preset = kDifficultyPresets[difficulty]!;
  return GameConfig(
    mode: GameMode.classic,
    rows: preset.rows,
    cols: preset.cols,
    mines: preset.mines,
    lives: preset.lives,
    seed: seed,
  );
}

/// Config del modo Contrarreloj / Blitz (plan §2.3): 9×9 con 10 minas, fijo.
GameConfig blitzConfig({int? seed}) => GameConfig(
      mode: GameMode.blitz,
      rows: 9,
      cols: 9,
      mines: 10,
      seed: seed,
    );

/// Config del modo Niebla (plan §2.2): mismas dificultades del clásico, pero con
/// visibilidad limitada. La lógica de ganar/perder es idéntica al clásico.
GameConfig fogConfig(Difficulty difficulty, {int? seed}) {
  assert(difficulty != Difficulty.custom, 'Niebla usa presets fijos');
  final preset = kDifficultyPresets[difficulty]!;
  return GameConfig(
    mode: GameMode.fog,
    rows: preset.rows,
    cols: preset.cols,
    mines: preset.mines,
    lives: preset.lives,
    seed: seed,
  );
}

/// Construye un [GameConfig] clásico personalizado, validando los límites.
GameConfig classicCustomConfig({
  required int rows,
  required int cols,
  required int mines,
  int? seed,
}) {
  assert(rows >= kCustomMinSide && rows <= kCustomMaxRows);
  assert(cols >= kCustomMinSide && cols <= kCustomMaxCols);
  assert(mines >= 1 && mines <= (rows * cols * kCustomMaxDensity).floor());
  return GameConfig(
    mode: GameMode.classic,
    rows: rows,
    cols: cols,
    mines: mines,
    seed: seed,
  );
}

import 'game_mode.dart';
import 'wave_modifier.dart';

/// Configuración inmutable de una partida (plan §6.4).
///
/// El engine recibe un [GameConfig] y, con su [seed], genera un tablero
/// determinista (mismo seed → mismo tablero).
class GameConfig {
  const GameConfig({
    required this.mode,
    required this.rows,
    required this.cols,
    required this.mines,
    this.lives = 1,
    this.seed,
    this.modifiers = const [],
    this.layers = 1,
  });

  final GameMode mode;
  final int rows;
  final int cols;
  final int mines;

  /// Vidas de la partida (1 en clásico; 3 en Oleadas, etc.).
  final int lives;

  /// Semilla del generador. `null` = aleatorio; fija en el Reto Diario.
  final int? seed;

  /// Modificadores activos (modo Oleadas).
  final List<WaveModifier> modifiers;

  /// Número de capas apiladas (modo 3D). 1 en el resto de modos.
  final int layers;

  /// Densidad de minas (0–1), útil para validación y puntaje.
  double get density => mines / (rows * cols);

  GameConfig copyWith({
    GameMode? mode,
    int? rows,
    int? cols,
    int? mines,
    int? lives,
    int? seed,
    List<WaveModifier>? modifiers,
    int? layers,
  }) {
    return GameConfig(
      mode: mode ?? this.mode,
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      mines: mines ?? this.mines,
      lives: lives ?? this.lives,
      seed: seed ?? this.seed,
      modifiers: modifiers ?? this.modifiers,
      layers: layers ?? this.layers,
    );
  }
}

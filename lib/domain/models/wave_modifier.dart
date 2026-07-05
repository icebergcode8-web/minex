/// Modificadores del modo Oleadas (plan §2.5).
///
/// Declarados desde Fase 1 para que [GameConfig] sea estable; su lógica se
/// implementa en `waves_engine.dart` (Fase 4).
enum WaveModifier {
  /// Minas encadenadas.
  chainedMines,

  /// Niebla parcial sobre el tablero.
  partialFog,

  /// Un porcentaje de números miente (±1).
  liarNumbers,

  /// Aparecen minas nuevas a mitad de la oleada.
  delayedMines,
}

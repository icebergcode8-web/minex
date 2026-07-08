import 'dart:math' as math;

/// Cálculo de visibilidad del modo Niebla (plan §2.2). **Lógica pura, sin
/// Flutter** (CLAUDE.md): recibe distancia y tiempo, devuelve un brillo 0..1.
/// El estado (foco del último toque, linterna activa) lo mantiene el provider;
/// el tiempo se pasa como parámetro, así es 100% determinista y testeable.
///
/// Reglas (§2.2):
/// - Solo son visibles las celdas dentro de un radio ([radius], 3 por defecto)
///   alrededor del último toque.
/// - El área iluminada se mantiene [holdMs] (4s) y luego se apaga con un fade
///   de [fadeMs] hasta la oscuridad total.
/// - La Linterna ilumina TODO el tablero mientras está activa.
class FogEngine {
  const FogEngine({
    this.radius = 3,
    this.holdMs = 4000,
    this.fadeMs = 800,
  });

  /// Radio de visibilidad en celdas (distancia Chebyshev).
  final int radius;

  /// Tiempo a pleno brillo antes de empezar a apagarse.
  final int holdMs;

  /// Duración del fade de brillo pleno a oscuridad.
  final int fadeMs;

  /// Distancia Chebyshev (rey de ajedrez) entre dos celdas.
  int chebyshev(int r1, int c1, int r2, int c2) =>
      math.max((r1 - r2).abs(), (c1 - c2).abs());

  /// Brillo 0..1 de una celda según su [distance] al foco y el tiempo
  /// transcurrido [sinceFocusMs] desde el último toque. Con [flashlightActive]
  /// todo es plenamente visible.
  double brightness({
    required int distance,
    required int sinceFocusMs,
    bool flashlightActive = false,
  }) {
    if (flashlightActive) return 1;
    if (distance > radius) return 0;
    if (sinceFocusMs <= holdMs) return 1;
    final t = (sinceFocusMs - holdMs) / fadeMs;
    return (1 - t).clamp(0.0, 1.0);
  }
}
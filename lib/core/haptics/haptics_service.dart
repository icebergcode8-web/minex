import 'package:flutter/services.dart';

/// Vibración háptica del juego (plan §4.3), usando el `HapticFeedback` nativo de
/// Flutter (sin plugins). Se gatea con [enabled], que [SettingsProvider]
/// mantiene sincronizado con el ajuste del jugador.
class HapticsService {
  HapticsService({this.enabled = true});

  bool enabled;

  /// Ligera: al revelar una celda.
  void reveal() {
    if (enabled) HapticFeedback.selectionClick();
  }

  /// Media: al poner/quitar bandera.
  void flag() {
    if (enabled) HapticFeedback.lightImpact();
  }

  /// Fuerte: al explotar una mina (derrota).
  void explosion() {
    if (enabled) HapticFeedback.heavyImpact();
  }

  /// Éxito: al ganar la partida.
  void victory() {
    if (enabled) HapticFeedback.mediumImpact();
  }
}
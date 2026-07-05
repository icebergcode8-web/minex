import 'package:flutter/material.dart';

/// Paleta del juego (plan §5.1). Tema oscuro por default.
///
/// Los números 1-8 usan la paleta clásica adaptada.
abstract final class AppColors {
  // Fondo y superficies
  static const bg = Color(0xFF0F1420);
  static const hiddenCell = Color(0xFF1E2636);
  static const hiddenCellHighlight = Color(0xFF2A3550);
  static const revealedCell = Color(0xFF141B2A);

  // Acentos
  static const primary = Color(0xFF4ADE80); // verde menta
  static const secondary = Color(0xFFFBBF24); // ámbar (monedas/banderas)
  static const danger = Color(0xFFF87171); // rojo coral (minas)

  // Texto
  static const textPrimary = Color(0xFFE5E7EB);
  static const textMuted = Color(0xFF9CA3AF);

  // Números 1-8 (índice 0 no se usa).
  static const numberColors = <Color>[
    Colors.transparent,
    Color(0xFF60A5FA), // 1 azul
    Color(0xFF4ADE80), // 2 verde
    Color(0xFFF87171), // 3 rojo
    Color(0xFFA78BFA), // 4 morado
    Color(0xFFDC2626), // 5 granate
    Color(0xFF22D3EE), // 6 cian
    Color(0xFFE5E7EB), // 7 blanco
    Color(0xFF9CA3AF), // 8 gris
  ];

  static Color forNumber(int n) =>
      (n >= 1 && n <= 8) ? numberColors[n] : textPrimary;
}

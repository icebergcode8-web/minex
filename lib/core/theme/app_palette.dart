import 'package:flutter/material.dart';

/// Paleta completa del juego expuesta como [ThemeExtension] para que TODO
/// —incluido el tablero pintado con `CustomPaint`— sea consciente del tema
/// claro/oscuro (plan §5.1). Se obtiene con `context.palette`.
///
/// Estética: minimalista moderno con ADN retro. Superficies neumórficas
/// suaves, acentos con glow y una geometría redondeada consistente.
@immutable
class BoardPalette extends ThemeExtension<BoardPalette> {
  const BoardPalette({
    required this.brightness,
    required this.bg,
    required this.bgGradientTop,
    required this.bgGradientBottom,
    required this.surface,
    required this.surfaceHi,
    required this.surfaceLow,
    required this.border,
    required this.primary,
    required this.secondary,
    required this.danger,
    required this.onAccent,
    required this.textPrimary,
    required this.textMuted,
    required this.shadowDark,
    required this.shadowLight,
    required this.numbers,
  });

  final Brightness brightness;

  /// Fondo base y los dos extremos del degradado sutil de profundidad.
  final Color bg;
  final Color bgGradientTop;
  final Color bgGradientBottom;

  /// Superficies: [surface] celda oculta / tarjetas, [surfaceHi] su highlight
  /// superior (relieve neumórfico), [surfaceLow] celda revelada / hundida.
  final Color surface;
  final Color surfaceHi;
  final Color surfaceLow;

  /// Borde sutil para tarjetas y chips.
  final Color border;

  /// Acentos del plan §5.1.
  final Color primary; // verde menta — éxito, botones
  final Color secondary; // ámbar — monedas, banderas
  final Color danger; // rojo coral — minas

  /// Color de texto/icono sobre un relleno de acento (primary/secondary).
  final Color onAccent;

  final Color textPrimary;
  final Color textMuted;

  /// Sombras para el efecto neumórfico (oscura abajo-derecha, clara arriba-izq).
  final Color shadowDark;
  final Color shadowLight;

  /// Colores de los números 1-8 (el índice 0 es transparente / sin uso).
  final List<Color> numbers;

  Color forNumber(int n) =>
      (n >= 1 && n < numbers.length) ? numbers[n] : textPrimary;

  bool get isDark => brightness == Brightness.dark;

  /// Degradado del fondo de las pantallas.
  LinearGradient get bgGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [bgGradientTop, bgGradientBottom],
      );

  // ── Tema oscuro (default, plan §5.1) ────────────────────────────────
  static const dark = BoardPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF0F1420),
    bgGradientTop: Color(0xFF161E30),
    bgGradientBottom: Color(0xFF0B0F18),
    surface: Color(0xFF1E2636),
    surfaceHi: Color(0xFF2A3550),
    surfaceLow: Color(0xFF141B2A),
    border: Color(0x1AFFFFFF),
    primary: Color(0xFF4ADE80),
    secondary: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    onAccent: Color(0xFF0F1420),
    textPrimary: Color(0xFFE5E7EB),
    textMuted: Color(0xFF9CA3AF),
    shadowDark: Color(0x66070B12),
    shadowLight: Color(0x14FFFFFF),
    numbers: <Color>[
      Color(0x00000000),
      Color(0xFF60A5FA), // 1 azul
      Color(0xFF4ADE80), // 2 verde
      Color(0xFFF87171), // 3 rojo
      Color(0xFFA78BFA), // 4 morado
      Color(0xFFDC2626), // 5 granate
      Color(0xFF22D3EE), // 6 cian
      Color(0xFFE5E7EB), // 7 blanco
      Color(0xFF9CA3AF), // 8 gris
    ],
  );

  // ── Tema claro (plan §5.1) ──────────────────────────────────────────
  static const light = BoardPalette(
    brightness: Brightness.light,
    bg: Color(0xFFF1F5F9),
    bgGradientTop: Color(0xFFFFFFFF),
    bgGradientBottom: Color(0xFFE6ECF4),
    surface: Color(0xFFFFFFFF),
    surfaceHi: Color(0xFFFFFFFF),
    surfaceLow: Color(0xFFE7EDF5),
    border: Color(0x14101828),
    primary: Color(0xFF12B76A),
    secondary: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    onAccent: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1E2636),
    textMuted: Color(0xFF64748B),
    shadowDark: Color(0x1A26324A),
    shadowLight: Color(0xF2FFFFFF),
    numbers: <Color>[
      Color(0x00000000),
      Color(0xFF2563EB), // 1 azul
      Color(0xFF15803D), // 2 verde
      Color(0xFFDC2626), // 3 rojo
      Color(0xFF7C3AED), // 4 morado
      Color(0xFF9F1239), // 5 granate
      Color(0xFF0891B2), // 6 cian
      Color(0xFF1E293B), // 7 negro
      Color(0xFF64748B), // 8 gris
    ],
  );

  @override
  BoardPalette copyWith({
    Brightness? brightness,
    Color? bg,
    Color? bgGradientTop,
    Color? bgGradientBottom,
    Color? surface,
    Color? surfaceHi,
    Color? surfaceLow,
    Color? border,
    Color? primary,
    Color? secondary,
    Color? danger,
    Color? onAccent,
    Color? textPrimary,
    Color? textMuted,
    Color? shadowDark,
    Color? shadowLight,
    List<Color>? numbers,
  }) {
    return BoardPalette(
      brightness: brightness ?? this.brightness,
      bg: bg ?? this.bg,
      bgGradientTop: bgGradientTop ?? this.bgGradientTop,
      bgGradientBottom: bgGradientBottom ?? this.bgGradientBottom,
      surface: surface ?? this.surface,
      surfaceHi: surfaceHi ?? this.surfaceHi,
      surfaceLow: surfaceLow ?? this.surfaceLow,
      border: border ?? this.border,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      danger: danger ?? this.danger,
      onAccent: onAccent ?? this.onAccent,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      shadowDark: shadowDark ?? this.shadowDark,
      shadowLight: shadowLight ?? this.shadowLight,
      numbers: numbers ?? this.numbers,
    );
  }

  @override
  BoardPalette lerp(covariant BoardPalette? other, double t) {
    if (other == null) return this;
    return BoardPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      bg: Color.lerp(bg, other.bg, t)!,
      bgGradientTop: Color.lerp(bgGradientTop, other.bgGradientTop, t)!,
      bgGradientBottom:
          Color.lerp(bgGradientBottom, other.bgGradientBottom, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHi: Color.lerp(surfaceHi, other.surfaceHi, t)!,
      surfaceLow: Color.lerp(surfaceLow, other.surfaceLow, t)!,
      border: Color.lerp(border, other.border, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      shadowDark: Color.lerp(shadowDark, other.shadowDark, t)!,
      shadowLight: Color.lerp(shadowLight, other.shadowLight, t)!,
      numbers: <Color>[
        for (var i = 0; i < numbers.length; i++)
          Color.lerp(numbers[i], other.numbers[i], t)!,
      ],
    );
  }
}

/// Acceso rápido a la paleta del tema actual: `context.palette`.
extension BoardPaletteX on BuildContext {
  BoardPalette get palette =>
      Theme.of(this).extension<BoardPalette>() ?? BoardPalette.dark;
}
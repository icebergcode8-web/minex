import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';

/// Temas claro/oscuro del juego (plan §5.1). Tipografía **Nunito** para la UI
/// (redondeada, amigable) y **Space Mono** para números y cronómetro
/// (guiño retro-digital). Cada tema incorpora su [BoardPalette] como extensión.
abstract final class AppTheme {
  static ThemeData get dark => _build(BoardPalette.dark);
  static ThemeData get light => _build(BoardPalette.light);

  /// Estilo monoespaciado para dígitos del tablero, cronómetro y récords.
  static TextStyle mono({
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.w700,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.spaceMono(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static ThemeData _build(BoardPalette p) {
    final base = ThemeData(
      brightness: p.brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: p.bg,
      colorScheme: ColorScheme(
        brightness: p.brightness,
        primary: p.primary,
        onPrimary: p.onAccent,
        secondary: p.secondary,
        onSecondary: p.onAccent,
        error: p.danger,
        onError: p.onAccent,
        surface: p.surface,
        onSurface: p.textPrimary,
      ),
      splashColor: p.primary.withValues(alpha: 0.12),
      highlightColor: p.primary.withValues(alpha: 0.06),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: p.textPrimary,
        centerTitle: false,
        titleTextStyle: GoogleFonts.nunito(
          color: p.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[p],
    );

    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: p.textPrimary,
        displayColor: p.textPrimary,
      ),
    );
  }
}
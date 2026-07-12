import 'package:flutter/material.dart';

import '../../domain/models/board_skin.dart';
import '../../domain/models/piece_skin.dart';
import 'app_palette.dart';

/// Mapeo de las skins (datos puros en `domain/models`) a colores concretos
/// (plan §3.2). Capa de presentación: el tablero pinta con la paleta resultante.
///
/// `BoardSkin.classic` devuelve la paleta del tema tal cual (consciente de
/// claro/oscuro); el resto son variantes con carácter propio que sobrescriben
/// las superficies/números del tablero conservando el fondo/textos del tema.
BoardPalette boardPaletteFor(BoardSkin skin, BoardPalette base) {
  switch (skin) {
    case BoardSkin.classic:
      return base;
    case BoardSkin.neon:
      return base.copyWith(
        surface: const Color(0xFF141A2A),
        surfaceHi: const Color(0xFF243154),
        surfaceLow: const Color(0xFF0B1120),
        border: const Color(0x3322D3EE),
        primary: const Color(0xFF22D3EE),
        secondary: const Color(0xFFF472B6),
        numbers: const [
          Color(0x00000000),
          Color(0xFF22D3EE),
          Color(0xFF4ADE80),
          Color(0xFFF472B6),
          Color(0xFFA78BFA),
          Color(0xFFFB7185),
          Color(0xFF38BDF8),
          Color(0xFFFDE68A),
          Color(0xFF94A3B8),
        ],
      );
    case BoardSkin.paper:
      return base.copyWith(
        surface: const Color(0xFFFBF6EA),
        surfaceHi: const Color(0xFFFFFFFF),
        surfaceLow: const Color(0xFFEFE6D2),
        border: const Color(0x22705B36),
        primary: const Color(0xFF3F7D5C),
        secondary: const Color(0xFFC28A2B),
        danger: const Color(0xFFB4472E),
        numbers: const [
          Color(0x00000000),
          Color(0xFF2E5AAC),
          Color(0xFF3F7D3F),
          Color(0xFFB4472E),
          Color(0xFF6B4C9A),
          Color(0xFF8A2E3E),
          Color(0xFF2E7D8A),
          Color(0xFF3A3226),
          Color(0xFF7A6E5A),
        ],
      );
    case BoardSkin.pixel:
      return base.copyWith(
        surface: const Color(0xFF3A4060),
        surfaceHi: const Color(0xFF505884),
        surfaceLow: const Color(0xFF1E2236),
        border: const Color(0x33FFFFFF),
        primary: const Color(0xFF7CF57C),
        secondary: const Color(0xFFFFD447),
        numbers: const [
          Color(0x00000000),
          Color(0xFF6EA8FF),
          Color(0xFF7CF57C),
          Color(0xFFFF6E6E),
          Color(0xFFC79BFF),
          Color(0xFFFF9E4A),
          Color(0xFF57E6E6),
          Color(0xFFF0F0F0),
          Color(0xFFB0B0B0),
        ],
      );
    case BoardSkin.ocean:
      return base.copyWith(
        surface: const Color(0xFF0E4C5C),
        surfaceHi: const Color(0xFF15697E),
        surfaceLow: const Color(0xFF06303B),
        border: const Color(0x3355E6E6),
        primary: const Color(0xFF34E0C8),
        secondary: const Color(0xFFFFC857),
        numbers: const [
          Color(0x00000000),
          Color(0xFF7FE3FF),
          Color(0xFF34E0C8),
          Color(0xFFFF8A7A),
          Color(0xFFB6A8FF),
          Color(0xFFFF6B8A),
          Color(0xFF57C9E6),
          Color(0xFFEAF7FA),
          Color(0xFF9DBEC7),
        ],
      );
    case BoardSkin.space:
      return base.copyWith(
        surface: const Color(0xFF241B45),
        surfaceHi: const Color(0xFF3A2E66),
        surfaceLow: const Color(0xFF130E28),
        border: const Color(0x33A78BFA),
        primary: const Color(0xFFA78BFA),
        secondary: const Color(0xFFFCD34D),
        numbers: const [
          Color(0x00000000),
          Color(0xFF8AB4FF),
          Color(0xFF6EE7B7),
          Color(0xFFFB7185),
          Color(0xFFC4B5FD),
          Color(0xFFF472B6),
          Color(0xFF67E8F9),
          Color(0xFFF5F3FF),
          Color(0xFFA5B4CB),
        ],
      );
  }
}

/// Colores de bandera y mina para una skin de piezas (plan §3.2).
({Color flag, Color mine}) pieceColorsFor(PieceSkin skin, BoardPalette base) {
  return switch (skin) {
    PieceSkin.classic => (flag: base.secondary, mine: base.danger),
    PieceSkin.gold => (flag: const Color(0xFFFFC94D), mine: const Color(0xFFE0A82E)),
    PieceSkin.neon => (flag: const Color(0xFF22D3EE), mine: const Color(0xFFF472B6)),
    PieceSkin.blossom => (flag: const Color(0xFFF9A8D4), mine: const Color(0xFFEC4899)),
  };
}
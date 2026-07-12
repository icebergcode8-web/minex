import 'package:flutter/material.dart';

import '../../domain/models/game_mode.dart';
import '../../l10n/app_localizations.dart';

/// Metadatos de presentación de cada modo para el carrusel (plan §8.3).
/// La lógica de cada modo llega en fases posteriores; aquí solo describe la
/// tarjeta y si está disponible.
class ModeInfo {
  const ModeInfo({
    required this.mode,
    required this.emoji,
    required this.icon,
    required this.available,
  });

  final GameMode mode;
  final String emoji;
  final IconData icon;
  final bool available;

  String name(AppLocalizations l) => switch (mode) {
        GameMode.classic => l.modeClassic,
        GameMode.fog => l.modeFog,
        GameMode.blitz => l.modeBlitz,
        GameMode.liar => l.modeLiar,
        GameMode.waves => l.modeWaves,
        GameMode.tower => l.modeTower,
        GameMode.daily => l.modeDaily,
      };

  String description(AppLocalizations l) => switch (mode) {
        GameMode.classic => l.modeClassicDesc,
        GameMode.fog => l.modeFogDesc,
        GameMode.blitz => l.modeBlitzDesc,
        GameMode.liar => l.modeLiarDesc,
        GameMode.waves => l.modeWavesDesc,
        GameMode.tower => l.modeTowerDesc,
        GameMode.daily => l.modeDailyDesc,
      };
}

/// Orden de presentación en el carrusel. Solo Clásico está disponible en Fase 2;
/// el resto se habilitan en sus fases (§ plan 2.x).
const List<ModeInfo> kModeCatalog = [
  ModeInfo(
      mode: GameMode.classic,
      emoji: '🟦',
      icon: Icons.grid_view_rounded,
      available: true),
  ModeInfo(
      mode: GameMode.blitz,
      emoji: '⚡',
      icon: Icons.bolt_rounded,
      available: true),
  ModeInfo(
      mode: GameMode.fog,
      emoji: '🌫️',
      icon: Icons.cloud_rounded,
      available: true),
  ModeInfo(
      mode: GameMode.liar,
      emoji: '🃏',
      icon: Icons.help_outline_rounded,
      available: true),
  ModeInfo(
      mode: GameMode.waves,
      emoji: '🌊',
      icon: Icons.waves_rounded,
      available: false),
  ModeInfo(
      mode: GameMode.tower,
      emoji: '🧊',
      icon: Icons.view_in_ar_rounded,
      available: false),
];
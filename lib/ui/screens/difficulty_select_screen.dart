import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/difficulty.dart';
import '../../core/constants/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/records_repository.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_mode.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/app_card.dart';

/// Selección de dificultad (plan §4.1). Sirve al Clásico (§2.1) y a Niebla
/// (§2.2), que comparten las mismas dificultades. El [mode] decide qué config
/// se construye y el título.
class DifficultySelectScreen extends StatelessWidget {
  const DifficultySelectScreen({super.key, this.mode = GameMode.classic});

  final GameMode mode;

  static const _classicOrder = [
    Difficulty.easy,
    Difficulty.medium,
    Difficulty.hard,
    Difficulty.expert,
  ];

  String _label(AppLocalizations l, Difficulty d) => switch (d) {
        Difficulty.easy => l.difficultyEasy,
        Difficulty.medium => l.difficultyMedium,
        Difficulty.hard => l.difficultyHard,
        Difficulty.expert => l.difficultyExpert,
        Difficulty.custom => l.difficultyExpert,
      };

  bool get _isLiar => mode == GameMode.liar;
  bool get _isTower => mode == GameMode.tower;

  /// Dificultades ofrecidas según el modo. Mentiroso solo Medio+ (§2.4);
  /// Torre 3D usa 3/5/7 capas (Fácil/Medio/Difícil, §2.6).
  List<Difficulty> get _order => _isLiar
      ? kLiarDifficulties
      : _isTower
          ? kTowerDifficulties
          : _classicOrder;

  GameConfig _configFor(Difficulty d) => switch (mode) {
        GameMode.fog => fogConfig(d),
        GameMode.liar => liarConfig(d),
        GameMode.tower => towerConfig(d),
        _ => classicConfig(d),
      };

  String _title(AppLocalizations l) => switch (mode) {
        GameMode.fog => l.modeFog,
        GameMode.liar => l.modeLiar,
        GameMode.tower => l.modeTower,
        _ => l.classicMode,
      };

  /// Subtítulo de cada tarjeta: resumen del tablero, o nº de capas en la Torre.
  String _subtitle(AppLocalizations l, Difficulty d) {
    if (_isTower) return l.towerLayersLabel(kTowerLayers[d]!);
    final p = kDifficultyPresets[d]!;
    return l.boardSummary(p.rows, p.cols, p.mines);
  }

  @override
  Widget build(BuildContext context) {
    final records = context.read<RecordsRepository>();
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(_title(l))),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            for (final d in _order)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DifficultyCard(
                  label: _label(l, d),
                  subtitle: _subtitle(l, d),
                  // Solo el Clásico persiste récords por dificultad (Fase 5).
                  bestTimeMs: mode == GameMode.classic
                      ? records.bestTimeMs(d)
                      : null,
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      Routes.game,
                      arguments: GameArgs(
                        config: _configFor(d),
                        difficulty: d,
                      ),
                    );
                  },
                ),
              ),
            // Tablero personalizado: solo en Clásico (§2.1).
            if (mode == GameMode.classic)
              _CustomCard(
                label: l.difficultyCustom,
                onTap: () =>
                    Navigator.of(context).pushNamed(Routes.customSetup),
              ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.label,
    required this.subtitle,
    required this.bestTimeMs,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final int? bestTimeMs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l = AppLocalizations.of(context)!;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: palette.textMuted),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.chevron_right_rounded, color: palette.primary),
              const SizedBox(height: 6),
              Text(
                bestTimeMs != null ? '🏆 ${formatRecord(bestTimeMs!)}' : l.noRecord,
                style: AppTheme.mono(
                  fontSize: 14,
                  color: palette.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tarjeta que lleva a la configuración de tablero personalizado (plan §2.1).
class _CustomCard extends StatelessWidget {
  const _CustomCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.tune_rounded, color: palette.primary),
          const SizedBox(width: 14),
          Text(label,
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              )),
          const Spacer(),
          Icon(Icons.chevron_right_rounded, color: palette.primary),
        ],
      ),
    );
  }
}
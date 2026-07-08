import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/difficulty.dart';
import '../../core/constants/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/records_repository.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/app_card.dart';

/// Selección de dificultad del modo clásico (plan §4.1). Se llega desde
/// ModeSelect; abre la partida.
class DifficultySelectScreen extends StatelessWidget {
  const DifficultySelectScreen({super.key});

  static const _order = [
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

  @override
  Widget build(BuildContext context) {
    final records = context.read<RecordsRepository>();
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.classicMode)),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            for (final d in _order)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DifficultyCard(
                  label: _label(l, d),
                  preset: kDifficultyPresets[d]!,
                  bestTimeMs: records.bestTimeMs(d),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      Routes.game,
                      arguments: GameArgs(
                        config: classicConfig(d),
                        difficulty: d,
                      ),
                    );
                  },
                ),
              ),
            // Tablero personalizado (plan §2.1).
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
    required this.preset,
    required this.bestTimeMs,
    required this.onTap,
  });

  final String label;
  final DifficultyPreset preset;
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
                l.boardSummary(preset.rows, preset.cols, preset.mines),
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
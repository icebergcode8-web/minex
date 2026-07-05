import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/difficulty.dart';
import '../../core/constants/routes.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/records_repository.dart';

/// Selección de dificultad del modo clásico (plan §4.1). En Fase 1 es el punto
/// de entrada al juego; en Fase 2 se antepone el ModeSelect.
class DifficultySelectScreen extends StatelessWidget {
  const DifficultySelectScreen({super.key});

  static const _order = [
    Difficulty.easy,
    Difficulty.medium,
    Difficulty.hard,
    Difficulty.expert,
  ];

  static const _labels = {
    Difficulty.easy: 'Fácil',
    Difficulty.medium: 'Medio',
    Difficulty.hard: 'Difícil',
    Difficulty.expert: 'Experto',
  };

  @override
  Widget build(BuildContext context) {
    final records = context.read<RecordsRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Clásico'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final d in _order)
            _DifficultyCard(
              label: _labels[d]!,
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
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.hiddenCell,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      '${preset.rows}×${preset.cols}  ·  ${preset.mines} minas',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(Icons.chevron_right, color: AppColors.primary),
                    const SizedBox(height: 6),
                    Text(
                      bestTimeMs != null
                          ? '🏆 ${formatRecord(bestTimeMs!)}'
                          : '— —',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

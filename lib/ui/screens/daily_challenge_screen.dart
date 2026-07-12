import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/game_mode.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/daily_provider.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/primary_button.dart';

/// Reto Diario y racha (plan §2.7). Un tablero determinista por día con
/// rotación de modo; completar días seguidos aumenta la racha.
class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({super.key});

  String _modeName(AppLocalizations l, GameMode mode) => switch (mode) {
        GameMode.classic => l.modeClassic,
        GameMode.fog => l.modeFog,
        GameMode.blitz => l.modeBlitz,
        GameMode.liar => l.modeLiar,
        GameMode.waves => l.modeWaves,
        GameMode.tower => l.modeTower,
        GameMode.daily => l.modeDaily,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final palette = context.palette;
    final daily = context.watch<DailyProvider>();
    final spec = daily.todaySpec;
    final done = daily.isCompletedToday;

    return Scaffold(
      appBar: AppBar(title: Text(l.dailyTitle)),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // Tarjeta del reto de hoy.
            AppCard(
              accent: palette.primary,
              selected: !done,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(l.dailyTodayMode,
                          style: TextStyle(
                              color: palette.textMuted,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (done ? palette.primary : palette.secondary)
                              .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          done ? '✓' : l.dailyBadge,
                          style: TextStyle(
                            color: done ? palette.primary : palette.secondary,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _modeName(l, spec.mode),
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (done)
                    Text(l.dailyDoneToday,
                        style: TextStyle(
                            color: palette.primary,
                            fontWeight: FontWeight.w700))
                  else
                    PrimaryButton(
                      label: l.dailyPlay,
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => Navigator.of(context).pushNamed(
                        Routes.game,
                        arguments: GameArgs(
                          config: spec.config,
                          difficulty: spec.difficulty,
                          isDaily: true,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Racha.
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    emoji: '🔥',
                    label: l.dailyStreakLabel,
                    value: '${daily.currentStreak}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    emoji: '🏆',
                    label: l.dailyBestStreak,
                    value: '${daily.longestStreak}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    emoji: '📅',
                    label: l.dailyCompletedTotal,
                    value: '${daily.completedCount}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
  });

  final String emoji;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTheme.mono(
              fontSize: 20,
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
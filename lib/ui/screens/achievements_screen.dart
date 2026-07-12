import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/achievement.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/achievements_provider.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/app_card.dart';

/// Logros locales (plan §3.2): ~30 metas con recompensa en monedas. Muestra el
/// progreso y cada logro con su estado (desbloqueado / bloqueado).
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = l.localeName;
    final palette = context.palette;
    final achievements = context.watch<AchievementsProvider>();
    final all = achievements.all;

    return Scaffold(
      appBar: AppBar(title: Text(l.achievementsTitle)),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _ProgressHeader(
              unlocked: achievements.unlockedCount,
              total: achievements.total,
            ),
            const SizedBox(height: 14),
            for (final a in all)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AchievementTile(
                  achievement: a,
                  locale: locale,
                  unlocked: achievements.isUnlocked(a.id),
                  palette: palette,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.unlocked, required this.total});
  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l = AppLocalizations.of(context)!;
    final ratio = total == 0 ? 0.0 : unlocked / total;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.achievementsProgress(unlocked, total),
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: palette.surfaceLow,
              valueColor: AlwaysStoppedAnimation(palette.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.locale,
    required this.unlocked,
    required this.palette,
  });

  final Achievement achievement;
  final String locale;
  final bool unlocked;
  final BoardPalette palette;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Opacity(
      opacity: unlocked ? 1 : 0.55,
      child: AppCard(
        accent: palette.primary,
        selected: unlocked,
        child: Row(
          children: [
            Text(
              unlocked ? achievement.emoji : '🔒',
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.name(locale),
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.description(locale),
                    style: TextStyle(color: palette.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 3),
                Text(
                  l.achievementReward(achievement.coins),
                  style: AppTheme.mono(
                    fontSize: 13,
                    color: palette.secondary,
                    fontWeight: FontWeight.w700,
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
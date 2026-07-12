import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants/difficulty.dart';
import '../../core/constants/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../data/repositories/savegame_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/daily_provider.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/coins_pill.dart';
import '../widgets/common/mine_logo.dart';
import '../widgets/common/primary_button.dart';

/// HomeScreen (plan §8.2). Fase 5: cabecera con monedas + racha, tarjeta de
/// Reto Diario y accesos a Tienda / Logros / Estadísticas / Ajustes.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l = AppLocalizations.of(context)!;
    final daily = context.watch<DailyProvider>();
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Barra superior: monedas + racha a la izquierda, accesos a la
              // derecha (plan §8.2).
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    CoinsPill(
                        onTap: () =>
                            Navigator.of(context).pushNamed(Routes.shop)),
                    const SizedBox(width: 8),
                    StreakPill(
                      streak: daily.currentStreak,
                      onTap: () =>
                          Navigator.of(context).pushNamed(Routes.daily),
                    ),
                    const Spacer(),
                    IconPillButton(
                      icon: Icons.emoji_events_rounded,
                      tooltip: l.navAchievements,
                      onTap: () =>
                          Navigator.of(context).pushNamed(Routes.achievements),
                    ),
                    const SizedBox(width: 10),
                    IconPillButton(
                      icon: Icons.storefront_rounded,
                      tooltip: l.navShop,
                      onTap: () =>
                          Navigator.of(context).pushNamed(Routes.shop),
                    ),
                    const SizedBox(width: 10),
                    IconPillButton(
                      icon: Icons.bar_chart_rounded,
                      tooltip: l.navStats,
                      onTap: () =>
                          Navigator.of(context).pushNamed(Routes.stats),
                    ),
                    const SizedBox(width: 10),
                    IconPillButton(
                      icon: Icons.settings_rounded,
                      tooltip: l.navSettings,
                      onTap: () =>
                          Navigator.of(context).pushNamed(Routes.settings),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const MineLogo(size: 100)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(
                      begin: -6,
                      end: 6,
                      duration: 1800.ms,
                      curve: Curves.easeInOut),
              const SizedBox(height: 20),
              Text(
                'MINEX',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.appTagline,
                style: TextStyle(color: palette.textMuted, fontSize: 15),
              ),
              const Spacer(),
              PrimaryButton(
                label: l.play,
                icon: Icons.play_arrow_rounded,
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.modeSelect),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
                    begin: 1,
                    end: 1.04,
                    duration: 1200.ms,
                    curve: Curves.easeInOut,
                  ),
              // Continuar la run de Oleadas guardada (plan §8.1/§2.5).
              if (context.read<SavegameRepository>().hasWaves) ...[
                const SizedBox(height: 14),
                PrimaryButton(
                  label: l.continueWaves,
                  icon: Icons.waves_rounded,
                  filled: false,
                  color: palette.secondary,
                  glow: false,
                  onPressed: () => Navigator.of(context).pushNamed(
                    Routes.game,
                    arguments: GameArgs(
                      config: wavesConfig(),
                      difficulty: Difficulty.easy,
                      resumeWaves: true,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Tarjeta de Reto Diario (plan §8.2).
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: _DailyCard(completed: daily.isCompletedToday),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.completed});
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l = AppLocalizations.of(context)!;
    return AppCard(
      accent: palette.secondary,
      selected: !completed,
      onTap: () => Navigator.of(context).pushNamed(Routes.daily),
      child: Row(
        children: [
          const Text('📅', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.dailyTitle,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  completed ? l.dailyDoneToday : l.modeDailyDesc,
                  style: TextStyle(color: palette.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(
            completed ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
            color: completed ? palette.primary : palette.textMuted,
          ),
        ],
      ),
    );
  }
}
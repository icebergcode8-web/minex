import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/mine_logo.dart';
import '../widgets/common/primary_button.dart';

/// HomeScreen (plan §8.2). Fase 2: branding rediseñado + accesos a
/// Estadísticas y Ajustes. Reto diario, monedas y tienda llegan en fases
/// posteriores.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Barra superior: accesos rápidos.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
              const MineLogo(size: 108)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(
                      begin: -6,
                      end: 6,
                      duration: 1800.ms,
                      curve: Curves.easeInOut),
              const SizedBox(height: 22),
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
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
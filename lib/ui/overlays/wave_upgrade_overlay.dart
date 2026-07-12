import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_palette.dart';
import '../../domain/engine/waves_engine.dart';
import '../../l10n/app_localizations.dart';

/// Selección de mejora tras completar una oleada (plan §2.5): 1 de 3.
class WaveUpgradeOverlay extends StatelessWidget {
  const WaveUpgradeOverlay({
    super.key,
    required this.choices,
    required this.onChoose,
  });

  final List<WaveUpgrade> choices;
  final void Function(WaveUpgrade) onChoose;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l = AppLocalizations.of(context)!;
    return Positioned.fill(
      child: ColoredBox(
        color: palette.bg.withValues(alpha: 0.9),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l.wavesChooseUpgrade,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ).animate().fadeIn().slideY(begin: -0.3, curve: Curves.easeOut),
                const SizedBox(height: 24),
                for (var i = 0; i < choices.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _UpgradeCard(
                      upgrade: choices[i],
                      onTap: () => onChoose(choices[i]),
                    )
                        .animate()
                        .fadeIn(delay: (100 * i).ms)
                        .slideX(begin: 0.2, curve: Curves.easeOutCubic),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({required this.upgrade, required this.onTap});

  final WaveUpgrade upgrade;
  final VoidCallback onTap;

  ({String emoji, String name, String desc}) _meta(AppLocalizations l) =>
      switch (upgrade) {
        WaveUpgrade.extraLife =>
          (emoji: '❤️', name: l.upgradeExtraLife, desc: l.upgradeExtraLifeDesc),
        WaveUpgrade.shield =>
          (emoji: '🛡️', name: l.upgradeShield, desc: l.upgradeShieldDesc),
        WaveUpgrade.radar =>
          (emoji: '🛰️', name: l.upgradeRadar, desc: l.upgradeRadarDesc),
        WaveUpgrade.vision =>
          (emoji: '👁️', name: l.upgradeVision, desc: l.upgradeVisionDesc),
        WaveUpgrade.itemCharge => (
            emoji: '⚡',
            name: l.upgradeItemCharge,
            desc: l.upgradeItemChargeDesc
          ),
      };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final m = _meta(AppLocalizations.of(context)!);
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Text(m.emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.desc,
                      style: TextStyle(color: palette.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.primary),
            ],
          ),
        ),
      ),
    );
  }
}
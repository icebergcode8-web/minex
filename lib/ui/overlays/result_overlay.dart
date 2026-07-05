import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common/primary_button.dart';
import '../widgets/effects/confetti.dart';

/// Overlay de resultado (plan §8.4): victoria o derrota.
///
/// El botón "Revivir" (rewarded) y "Doblar monedas" se conectan en Fase 3.
class ResultOverlay extends StatelessWidget {
  const ResultOverlay({
    super.key,
    required this.won,
    required this.elapsed,
    required this.isNewRecord,
    required this.onPlayAgain,
    required this.onExit,
  });

  final bool won;
  final Duration elapsed;
  final bool isNewRecord;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l = AppLocalizations.of(context)!;
    final accent = won ? palette.primary : palette.danger;
    return Positioned.fill(
      child: Stack(
        children: [
          ColoredBox(
            color: palette.bg.withValues(alpha: 0.86),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    won ? l.victory : l.defeat,
                    style: TextStyle(
                      color: accent,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ).animate().scale(
                        duration: 320.ms,
                        curve: Curves.easeOutBack,
                        begin: const Offset(0.6, 0.6),
                      ),
                  const SizedBox(height: 8),
                  if (won) ...[
                    Text.rich(
                      TextSpan(
                        text: '${l.timeLabel}  ',
                        style: TextStyle(
                            color: palette.textPrimary, fontSize: 16),
                        children: [
                          TextSpan(
                            text: formatClock(elapsed),
                            style: AppTheme.mono(
                              fontSize: 16,
                              color: palette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isNewRecord)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: palette.secondary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(l.newRecord,
                              style: TextStyle(
                                color: palette.secondary,
                                fontWeight: FontWeight.w800,
                              )),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .fadeIn()
                            .then()
                            .tint(color: palette.secondary.withValues(alpha: 0.3)),
                      ),
                  ] else
                    Text(l.youHitMine,
                        style: TextStyle(color: palette.textMuted)),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: won ? l.playAgain : l.retry,
                    icon: Icons.refresh,
                    onPressed: onPlayAgain,
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: l.menu,
                    icon: Icons.home_outlined,
                    filled: false,
                    color: palette.textMuted,
                    onPressed: onExit,
                  ),
                ],
              ),
            ),
          ),
          if (won) const Positioned.fill(child: ConfettiOverlay()),
        ],
      ),
    );
  }
}
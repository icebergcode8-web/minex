import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../widgets/common/primary_button.dart';

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
    final accent = won ? AppColors.primary : AppColors.danger;
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.bg.withValues(alpha: 0.86),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                won ? '¡Victoria!' : 'Boom 💥',
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
                Text('Tiempo  ${formatClock(elapsed)}',
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 16)),
                if (isNewRecord)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('¡NUEVO RÉCORD!',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w800,
                          )),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn().then().tint(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                        ),
                  ),
              ] else
                const Text('Tocaste una mina',
                    style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 28),
              PrimaryButton(
                label: won ? 'Jugar de nuevo' : 'Reintentar',
                icon: Icons.refresh,
                onPressed: onPlayAgain,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Menú',
                icon: Icons.home_outlined,
                filled: false,
                color: AppColors.textMuted,
                onPressed: onExit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

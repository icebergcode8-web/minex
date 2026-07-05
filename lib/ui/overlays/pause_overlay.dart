import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../widgets/common/primary_button.dart';

/// Overlay de pausa (plan §4.1). Resume / Reiniciar / Salir.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return _OverlayScrim(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Pausa',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 24),
          PrimaryButton(
              label: 'Continuar', icon: Icons.play_arrow, onPressed: onResume),
          const SizedBox(height: 12),
          PrimaryButton(
              label: 'Reiniciar',
              icon: Icons.refresh,
              filled: false,
              onPressed: onRestart),
          const SizedBox(height: 12),
          PrimaryButton(
              label: 'Salir',
              icon: Icons.home_outlined,
              filled: false,
              color: AppColors.textMuted,
              onPressed: onExit),
        ],
      ),
    );
  }
}

class _OverlayScrim extends StatelessWidget {
  const _OverlayScrim({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.bg.withValues(alpha: 0.82),
        child: Center(child: child),
      ),
    );
  }
}

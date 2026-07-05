import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../l10n/app_localizations.dart';
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
    final palette = context.palette;
    final l = AppLocalizations.of(context)!;
    return _OverlayScrim(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.pauseTitle,
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 24),
          PrimaryButton(
              label: l.resume, icon: Icons.play_arrow, onPressed: onResume),
          const SizedBox(height: 12),
          PrimaryButton(
              label: l.restart,
              icon: Icons.refresh,
              filled: false,
              onPressed: onRestart),
          const SizedBox(height: 12),
          PrimaryButton(
              label: l.exit,
              icon: Icons.home_outlined,
              filled: false,
              color: palette.textMuted,
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
        color: context.palette.bg.withValues(alpha: 0.82),
        child: Center(child: child),
      ),
    );
  }
}
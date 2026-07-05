import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/game_provider.dart';

/// HUD superior de la partida (plan §8.4): pausa, contador de minas y
/// cronómetro. El cronómetro escucha su propio `ValueNotifier`, así que se
/// actualiza sin reconstruir el tablero (plan §6.3 regla 4).
class GameTopHud extends StatelessWidget {
  const GameTopHud({super.key, required this.onPause});

  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _HudButton(icon: Icons.pause, onTap: onPause),
          const Spacer(),
          _HudChip(
            icon: Icons.flag,
            color: palette.danger,
            label: '${gp.minesRemaining}',
          ),
          const SizedBox(width: 10),
          ValueListenableBuilder<Duration>(
            valueListenable: gp.elapsed,
            builder: (_, value, child) => _HudChip(
              icon: Icons.timer_outlined,
              color: palette.primary,
              label: formatClock(value),
              monospace: true,
            ),
          ),
          const Spacer(),
          // Placeholder de ítems (se activa en Fase 4).
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

/// Barra de acción inferior (plan §4.3): toggle 💣/🚩 crítico en táctiles.
class GameActionBar extends StatelessWidget {
  const GameActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final palette = context.palette;
    final l = AppLocalizations.of(context)!;
    final flagMode = gp.flagMode;
    final accent = flagMode ? palette.secondary : palette.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: gp.toggleFlagMode,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: flagMode ? 0.16 : 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.22),
                    blurRadius: 16,
                    spreadRadius: -6,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(flagMode ? '🚩' : '⛏️',
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text(
                    flagMode ? l.flag : l.reveal,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.icon,
    required this.color,
    required this.label,
    this.monospace = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: monospace
                ? AppTheme.mono(
                    fontSize: 15,
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                  )
                : TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
          ),
        ],
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: palette.textPrimary, size: 22),
        ),
      ),
    );
  }
}
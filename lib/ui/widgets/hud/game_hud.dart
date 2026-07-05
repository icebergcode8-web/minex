import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _HudButton(icon: Icons.pause, onTap: onPause),
          const Spacer(),
          _HudChip(
            icon: Icons.flag,
            color: AppColors.danger,
            label: '${gp.minesRemaining}',
          ),
          const SizedBox(width: 10),
          ValueListenableBuilder<Duration>(
            valueListenable: gp.elapsed,
            builder: (_, value, child) => _HudChip(
              icon: Icons.timer_outlined,
              color: AppColors.primary,
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
    final flagMode = gp.flagMode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: gp.toggleFlagMode,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: flagMode
                    ? AppColors.secondary.withValues(alpha: 0.18)
                    : AppColors.hiddenCell,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: flagMode ? AppColors.secondary : AppColors.hiddenCellHighlight,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(flagMode ? '🚩' : '⛏️',
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text(
                    flagMode ? 'Bandera' : 'Revelar',
                    style: TextStyle(
                      color: flagMode ? AppColors.secondary : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.hiddenCell,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontFeatures: monospace
                  ? const [FontFeature.tabularFigures()]
                  : null,
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
    return Material(
      color: AppColors.hiddenCell,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      ),
    );
  }
}

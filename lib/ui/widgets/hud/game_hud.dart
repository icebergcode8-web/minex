import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/wave_modifier.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/game_provider.dart';

/// HUD superior de la partida (plan §8.4): pausa, contador de minas/puntos y
/// cronómetro. El cronómetro escucha su propio `ValueNotifier`, así que se
/// actualiza sin reconstruir el tablero (plan §6.3 regla 4).
class GameTopHud extends StatelessWidget {
  const GameTopHud({super.key, required this.onPause});

  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final palette = context.palette;

    if (gp.isWaves) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _HudButton(icon: Icons.pause, onTap: onPause),
            const Spacer(),
            _HudChip(
              icon: Icons.favorite_rounded,
              color: palette.danger,
              label: '${gp.lives}',
            ),
            const SizedBox(width: 8),
            _HudChip(
              icon: Icons.waves_rounded,
              color: palette.primary,
              label: '${gp.wave}',
            ),
            const SizedBox(width: 8),
            _HudChip(
              icon: Icons.star_rounded,
              color: palette.secondary,
              label: '${gp.wavesScore}',
            ),
            if (gp.currentModifier != null) ...[
              const SizedBox(width: 8),
              _ModifierChip(modifier: gp.currentModifier!),
            ],
            const Spacer(),
            _ShieldBadge(count: gp.shieldCharges),
          ],
        ),
      );
    }

    if (gp.isTower) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _HudButton(icon: Icons.pause, onTap: onPause),
            const Spacer(),
            _HudChip(
              icon: Icons.layers_rounded,
              color: palette.primary,
              label: '${gp.towerLayer}/${gp.towerLayerCount}',
            ),
            const SizedBox(width: 8),
            _HudChip(
              icon: Icons.flag,
              color: palette.danger,
              label: '${gp.minesRemaining}',
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<Duration>(
              valueListenable: gp.elapsed,
              builder: (_, value, _) => _HudChip(
                icon: Icons.timer_outlined,
                color: palette.primary,
                label: formatClock(value),
                monospace: true,
              ),
            ),
            const Spacer(),
            const SizedBox(width: 40),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _HudButton(icon: Icons.pause, onTap: onPause),
          const Spacer(),
          if (gp.isBlitz)
            _HudChip(
              icon: Icons.star_rounded,
              color: palette.secondary,
              label: '${gp.blitzScore}',
            )
          else
            _HudChip(
              icon: Icons.flag,
              color: palette.danger,
              label: '${gp.minesRemaining}',
            ),
          const SizedBox(width: 10),
          ValueListenableBuilder<Duration>(
            valueListenable: gp.elapsed,
            builder: (_, value, _) => _HudChip(
              icon: Icons.timer_outlined,
              color: gp.isBlitz && value.inSeconds <= 10
                  ? palette.danger
                  : palette.primary,
              label: formatClock(value),
              monospace: true,
            ),
          ),
          const Spacer(),
          if (gp.isBlitz)
            _ItemButton(
              emoji: '❄️',
              charges: gp.freezerCharges,
              onTap: gp.useFreezer,
            )
          else if (gp.isFog)
            _ItemButton(
              emoji: '🔦',
              charges: gp.flashlightCharges,
              onTap: gp.useFlashlight,
            )
          else if (gp.isLiar)
            _ItemButton(
              emoji: '🔍',
              charges: gp.scannerCharges,
              active: gp.scannerMode,
              onTap: gp.toggleScanner,
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}

/// Barra de combo del modo Blitz (plan §5.2): glow pulsante y multiplicador.
class GameComboBar extends StatelessWidget {
  const GameComboBar({super.key});

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    if (!gp.isBlitz) return const SizedBox.shrink();
    final palette = context.palette;
    final l = AppLocalizations.of(context)!;
    final mult = gp.comboMultiplier;
    final active = mult > 1;
    final color = active ? palette.secondary : palette.textMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Text(
            l.comboLabel,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: gp.comboProgress,
                minHeight: 8,
                backgroundColor: palette.surface,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '×$mult',
            style: AppTheme.mono(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
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

class _ItemButton extends StatelessWidget {
  const _ItemButton({
    required this.emoji,
    required this.charges,
    required this.onTap,
    this.active = false,
  });

  final String emoji;
  final int charges;
  final VoidCallback onTap;

  /// Resalta el botón cuando el ítem es un modo activo (p. ej. Escáner armado).
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = charges > 0;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: active
            ? palette.secondary.withValues(alpha: 0.18)
            : palette.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onTap : null,
          child: Container(
            decoration: active
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.secondary, width: 2),
                  )
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text('$charges',
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Emoji + nombre localizado de un modificador de oleada (§2.5).
({String emoji, String name}) modifierMeta(
    WaveModifier m, AppLocalizations l) {
  return switch (m) {
    WaveModifier.chainedMines => (emoji: '⛓️', name: l.modChainedMines),
    WaveModifier.partialFog => (emoji: '🌫️', name: l.modPartialFog),
    WaveModifier.liarNumbers => (emoji: '🃏', name: l.modLiarNumbers),
    WaveModifier.delayedMines => (emoji: '⏱️', name: l.modDelayedMines),
  };
}

/// Chip que indica el modificador activo de la oleada.
class _ModifierChip extends StatelessWidget {
  const _ModifierChip({required this.modifier});
  final WaveModifier modifier;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final meta = modifierMeta(modifier, AppLocalizations.of(context)!);
    return Tooltip(
      message: meta.name,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: palette.secondary.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.secondary.withValues(alpha: 0.5)),
        ),
        child: Text(meta.emoji, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

/// Insignia del escudo en Oleadas: solo visible si hay cargas.
class _ShieldBadge extends StatelessWidget {
  const _ShieldBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox(width: 40);
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🛡️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text('$count',
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              )),
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
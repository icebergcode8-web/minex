import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Tarjeta de superficie con relieve neumórfico sutil (plan §5.1): highlight
/// arriba-izquierda, sombra abajo-derecha. Base del look minimalista moderno.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.radius = 20,
    this.accent,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double radius;

  /// Si se define, se usa como borde/tinte cuando [selected] es `true`.
  final Color? accent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final borderColor = selected && accent != null
        ? accent!.withValues(alpha: 0.9)
        : palette.border;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: selected ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: palette.shadowDark,
            blurRadius: 18,
            offset: const Offset(0, 10),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Botón circular de icono para barras superiores (ajustes, stats, back).
class IconPillButton extends StatelessWidget {
  const IconPillButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final button = Material(
      color: palette.surface,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: palette.textPrimary, size: 22),
        ),
      ),
    );
    return tooltip == null
        ? button
        : Tooltip(message: tooltip!, child: button);
  }
}
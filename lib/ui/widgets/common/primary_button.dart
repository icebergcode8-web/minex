import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Botón principal del juego con estilo pill (plan §5.1).
///
/// Consciente del tema (claro/oscuro) y con feedback táctil: se hunde
/// levemente al presionar y —si está relleno— proyecta un glow suave del color
/// de acento para un look moderno.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.filled = true,
    this.glow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Color de acento. `null` = primary del tema.
  final Color? color;
  final bool filled;
  final bool glow;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = widget.color ?? palette.primary;
    final fg = widget.filled ? palette.onAccent : accent;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
          decoration: BoxDecoration(
            color: widget.filled ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: widget.filled
                ? null
                : Border.all(color: accent.withValues(alpha: 0.9), width: 2),
            boxShadow: widget.filled && widget.glow && !_pressed
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.38),
                      blurRadius: 22,
                      spreadRadius: -4,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
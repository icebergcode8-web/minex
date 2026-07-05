import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Marca del juego: una mina minimalista dentro de un cuadrado redondeado con
/// degradado de acento. Vectorial (`CustomPaint`), escalable y sin assets
/// (plan §5.1). Le da al branding un toque moderno y diferenciado.
class MineLogo extends StatelessWidget {
  const MineLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.primary,
            Color.lerp(palette.primary, palette.secondary, 0.55)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.35),
            blurRadius: size * 0.35,
            spreadRadius: -size * 0.08,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: CustomPaint(painter: _MineMarkPainter(palette.onAccent)),
    );
  }
}

class _MineMarkPainter extends CustomPainter {
  _MineMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.2;
    final paint = Paint()..color = color;
    canvas.drawCircle(c, r, paint);

    final spike = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final o = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + o * (r * 0.7), c + o * (r * 1.7), spike);
    }
    // Destello.
    canvas.drawCircle(
      c - Offset(r * 0.35, r * 0.35),
      r * 0.28,
      Paint()..color = color.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant _MineMarkPainter old) => old.color != color;
}
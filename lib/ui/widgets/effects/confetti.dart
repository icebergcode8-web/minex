import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Confeti de victoria (plan §5.2): ~60 partículas con física simple (posición,
/// velocidad, gravedad y rotación) en un único `Ticker`. Se emite una vez al
/// montarse. Ligero y sin assets.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, this.count = 60});

  final int count;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final List<_Particle> _particles;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();

  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.count, (_) => _spawn());
  }

  _Particle _spawn() {
    final angle = -math.pi / 2 + (_rng.nextDouble() - 0.5) * 1.2;
    final speed = 0.6 + _rng.nextDouble() * 0.9;
    return _Particle(
      x: 0.5 + (_rng.nextDouble() - 0.5) * 0.3,
      y: 0.55,
      vx: math.cos(angle) * speed,
      vy: math.sin(angle) * speed,
      rotation: _rng.nextDouble() * math.pi,
      rotationSpeed: (_rng.nextDouble() - 0.5) * 6,
      size: 5 + _rng.nextDouble() * 7,
      colorSeed: _rng.nextInt(3),
      shape: _rng.nextInt(2),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final colors = [palette.primary, palette.secondary, palette.danger];
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(
            particles: _particles,
            t: _c.value,
            colors: colors,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.colorSeed,
    required this.shape,
  });

  final double x, y, vx, vy, rotation, rotationSpeed, size;
  final int colorSeed, shape;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.particles,
    required this.t,
    required this.colors,
  });

  final List<_Particle> particles;
  final double t;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    const gravity = 0.9;
    final fade = (1 - t).clamp(0.0, 1.0);
    for (final p in particles) {
      // Integración simple: x lineal, y con gravedad. Coordenadas normalizadas.
      final px = (p.x + p.vx * t * 0.8) * size.width;
      final py = (p.y + p.vy * t + 0.5 * gravity * t * t) * size.height;
      if (py > size.height) continue;

      final paint = Paint()
        ..color = colors[p.colorSeed].withValues(alpha: fade);
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation + p.rotationSpeed * t);
      final s = p.size;
      if (p.shape == 0) {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.5), paint);
      } else {
        canvas.drawCircle(Offset.zero, s * 0.4, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
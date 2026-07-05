import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Fondo con degradado sutil de profundidad (plan §5.1). Envuelve el contenido
/// de una pantalla para darle el aire moderno del rediseño.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: context.palette.bgGradient),
      child: child,
    );
  }
}
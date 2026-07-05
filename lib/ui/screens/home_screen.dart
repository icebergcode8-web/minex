import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/routes.dart';
import '../widgets/common/primary_button.dart';

/// HomeScreen (plan §8.2). Versión de Fase 1: branding + botón JUGAR.
/// Reto diario, monedas, tienda, etc. se agregan en fases posteriores.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💣', style: TextStyle(fontSize: 96))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: -6, end: 6, duration: 1800.ms, curve: Curves.easeInOut),
              const SizedBox(height: 12),
              const Text(
                'MINEX',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Buscaminas retro moderno',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 48),
              PrimaryButton(
                label: 'JUGAR',
                icon: Icons.play_arrow,
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.difficulty),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
                    begin: 1,
                    end: 1.04,
                    duration: 1200.ms,
                    curve: Curves.easeInOut,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

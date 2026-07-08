import 'package:flutter/material.dart';

import '../../core/constants/difficulty.dart';
import '../../core/constants/mode_catalog.dart';
import '../../core/constants/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../domain/models/game_mode.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common/app_background.dart';

/// Selección de modo con carrusel horizontal (plan §8.3). En Fase 2 solo
/// Clásico está disponible; el resto muestran "Próximamente".
class ModeSelectScreen extends StatefulWidget {
  const ModeSelectScreen({super.key});

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  final PageController _controller = PageController(viewportFraction: 0.82);
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _page = _controller.page ?? 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Lanza el modo elegido. Clásico pasa por selección de dificultad; Blitz es
  /// de tablero fijo (§2.3) y entra directo a la partida.
  void _launch(BuildContext context, GameMode mode) {
    final nav = Navigator.of(context);
    switch (mode) {
      case GameMode.blitz:
        nav.pushNamed(
          Routes.game,
          arguments: GameArgs(
            config: blitzConfig(),
            difficulty: Difficulty.easy, // no aplica a Blitz; récord propio
          ),
        );
      case GameMode.classic:
      default:
        nav.pushNamed(Routes.difficulty);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.modesTitle)),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: kModeCatalog.length,
                  itemBuilder: (context, index) {
                    final info = kModeCatalog[index];
                    // Escala parallax: la card central resalta (plan §8.3).
                    final delta = (index - _page).abs().clamp(0.0, 1.0);
                    final scale = 1 - delta * 0.12;
                    return Transform.scale(
                      scale: scale,
                      child: _ModeCard(
                        info: info,
                        onTap: info.available
                            ? () => _launch(context, info.mode)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _Dots(count: kModeCatalog.length, page: _page),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.info, required this.onTap});

  final ModeInfo info;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l = AppLocalizations.of(context)!;
    final locked = !info.available;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                palette.surface,
                Color.lerp(palette.surface, palette.bg, 0.4)!,
              ],
            ),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: palette.shadowDark,
                blurRadius: 28,
                offset: const Offset(0, 16),
                spreadRadius: -10,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (locked)
                      Align(
                        alignment: Alignment.topRight,
                        child: _Badge(
                            text: l.comingSoon, color: palette.secondary),
                      ),
                    const Spacer(),
                    Text(info.emoji, style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 20),
                    Text(
                      info.name(l),
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      info.description(l),
                      style: TextStyle(color: palette.textMuted, fontSize: 15),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          locked ? Icons.lock_rounded : Icons.play_arrow_rounded,
                          color: locked ? palette.textMuted : palette.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          locked ? l.comingSoon : l.play,
                          style: TextStyle(
                            color: locked ? palette.textMuted : palette.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.page});
  final int count;
  final double page;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final active = page.round();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == active ? palette.primary : palette.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}
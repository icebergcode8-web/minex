import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common/primary_button.dart';
import '../widgets/effects/confetti.dart';

/// Overlay de resultado (plan §8.4): victoria o derrota.
///
/// El botón "Revivir" (rewarded) y "Doblar monedas" se conectan en Fase 3.
class ResultOverlay extends StatelessWidget {
  const ResultOverlay({
    super.key,
    required this.won,
    required this.elapsed,
    required this.isNewRecord,
    required this.onPlayAgain,
    required this.onExit,
    this.isBlitz = false,
    this.blitzScore = 0,
    this.blitzBoards = 0,
    this.timeUp = false,
    this.isWaves = false,
    this.wavesReached = 0,
    this.wavesScore = 0,
    this.coinsEarned = 0,
    this.unlockedAchievements = const [],
  });

  final bool won;
  final Duration elapsed;
  final bool isNewRecord;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  // Economía (plan §3.2): monedas ganadas y logros desbloqueados en la partida.
  final int coinsEarned;
  final List<String> unlockedAchievements;

  // Blitz (plan §2.3): el resultado muestra puntaje en vez de tiempo/récord.
  final bool isBlitz;
  final int blitzScore;
  final int blitzBoards;
  final bool timeUp;

  // Oleadas (plan §2.5): game over con oleada alcanzada y puntaje.
  final bool isWaves;
  final int wavesReached;
  final int wavesScore;

  /// Monedas ganadas + logros desbloqueados (Fase 5). Aparece con una animación
  /// suave cuando las recompensas se calculan (de forma asíncrona).
  Widget _rewardsSection(BuildContext context) {
    if (coinsEarned <= 0 && unlockedAchievements.isEmpty) {
      return const SizedBox.shrink();
    }
    final palette = context.palette;
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (coinsEarned > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: palette.secondary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    l.resultCoins(coinsEarned),
                    style: TextStyle(
                      color: palette.secondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          for (final name in unlockedAchievements)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '🏆 ${l.achievementUnlocked} $name',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.2, end: 0);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l = AppLocalizations.of(context)!;
    // En Blitz el "confeti/verde" celebra un buen marcador aunque termine por
    // tiempo; el rojo se reserva para morir por mina.
    final celebrate = won || (isBlitz && timeUp);
    final accent = celebrate ? palette.primary : palette.danger;

    if (isBlitz) {
      return _buildBlitz(context, palette, l, accent, celebrate);
    }
    if (isWaves) {
      return _buildWaves(context, palette, l);
    }
    return Positioned.fill(
      child: Stack(
        children: [
          ColoredBox(
            color: palette.bg.withValues(alpha: 0.86),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    won ? l.victory : l.defeat,
                    style: TextStyle(
                      color: accent,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ).animate().scale(
                        duration: 320.ms,
                        curve: Curves.easeOutBack,
                        begin: const Offset(0.6, 0.6),
                      ),
                  const SizedBox(height: 8),
                  if (won) ...[
                    Text.rich(
                      TextSpan(
                        text: '${l.timeLabel}  ',
                        style: TextStyle(
                            color: palette.textPrimary, fontSize: 16),
                        children: [
                          TextSpan(
                            text: formatClock(elapsed),
                            style: AppTheme.mono(
                              fontSize: 16,
                              color: palette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isNewRecord)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: palette.secondary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(l.newRecord,
                              style: TextStyle(
                                color: palette.secondary,
                                fontWeight: FontWeight.w800,
                              )),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .fadeIn()
                            .then()
                            .tint(color: palette.secondary.withValues(alpha: 0.3)),
                      ),
                  ] else
                    Text(l.youHitMine,
                        style: TextStyle(color: palette.textMuted)),
                  _rewardsSection(context),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: won ? l.playAgain : l.retry,
                    icon: Icons.refresh,
                    onPressed: onPlayAgain,
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: l.menu,
                    icon: Icons.home_outlined,
                    filled: false,
                    color: palette.textMuted,
                    onPressed: onExit,
                  ),
                ],
              ),
            ),
          ),
          if (won) const Positioned.fill(child: ConfettiOverlay()),
        ],
      ),
    );
  }

  /// Resultado del modo Blitz (plan §2.3): puntaje, tableros y récord.
  Widget _buildBlitz(
    BuildContext context,
    BoardPalette palette,
    AppLocalizations l,
    Color accent,
    bool celebrate,
  ) {
    return Positioned.fill(
      child: Stack(
        children: [
          ColoredBox(
            color: palette.bg.withValues(alpha: 0.88),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeUp ? l.blitzTimeUp : l.defeat,
                    style: TextStyle(
                      color: accent,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ).animate().scale(
                        duration: 320.ms,
                        curve: Curves.easeOutBack,
                        begin: const Offset(0.6, 0.6),
                      ),
                  const SizedBox(height: 18),
                  Text(
                    '$blitzScore',
                    style: AppTheme.mono(
                      fontSize: 56,
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(l.blitzScoreLabel,
                      style: TextStyle(color: palette.textMuted)),
                  const SizedBox(height: 10),
                  Text(
                    '${l.blitzBoardsLabel}: $blitzBoards',
                    style: TextStyle(color: palette.textMuted, fontSize: 14),
                  ),
                  if (isNewRecord)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: palette.secondary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(l.newRecord,
                            style: TextStyle(
                              color: palette.secondary,
                              fontWeight: FontWeight.w800,
                            )),
                      ),
                    ),
                  _rewardsSection(context),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: l.playAgain,
                    icon: Icons.refresh,
                    onPressed: onPlayAgain,
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: l.menu,
                    icon: Icons.home_outlined,
                    filled: false,
                    color: palette.textMuted,
                    onPressed: onExit,
                  ),
                ],
              ),
            ),
          ),
          if (celebrate && isNewRecord)
            const Positioned.fill(child: ConfettiOverlay()),
        ],
      ),
    );
  }

  /// Resultado del modo Oleadas (plan §2.5): game over con oleada y puntaje.
  Widget _buildWaves(
    BuildContext context,
    BoardPalette palette,
    AppLocalizations l,
  ) {
    return Positioned.fill(
      child: Stack(
        children: [
          ColoredBox(
            color: palette.bg.withValues(alpha: 0.9),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.wavesGameOver,
                    style: TextStyle(
                      color: palette.danger,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ).animate().scale(
                        duration: 320.ms,
                        curve: Curves.easeOutBack,
                        begin: const Offset(0.6, 0.6),
                      ),
                  const SizedBox(height: 16),
                  Text(
                    '$wavesScore',
                    style: AppTheme.mono(
                      fontSize: 56,
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(l.wavesScoreLabel,
                      style: TextStyle(color: palette.textMuted)),
                  const SizedBox(height: 10),
                  Text(
                    l.wavesReached(wavesReached),
                    style: TextStyle(color: palette.textMuted, fontSize: 14),
                  ),
                  if (isNewRecord)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: palette.secondary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(l.newRecord,
                            style: TextStyle(
                              color: palette.secondary,
                              fontWeight: FontWeight.w800,
                            )),
                      ),
                    ),
                  _rewardsSection(context),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: l.playAgain,
                    icon: Icons.refresh,
                    onPressed: onPlayAgain,
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: l.menu,
                    icon: Icons.home_outlined,
                    filled: false,
                    color: palette.textMuted,
                    onPressed: onExit,
                  ),
                ],
              ),
            ),
          ),
          if (isNewRecord) const Positioned.fill(child: ConfettiOverlay()),
        ],
      ),
    );
  }
}
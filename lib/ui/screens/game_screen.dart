import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../data/repositories/records_repository.dart';
import '../../data/repositories/savegame_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/models/game_status.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/game_provider.dart';
import '../overlays/pause_overlay.dart';
import '../overlays/result_overlay.dart';
import '../overlays/wave_upgrade_overlay.dart';
import '../widgets/board/board_widget.dart';
import '../widgets/common/app_background.dart';
import '../widgets/hud/game_hud.dart';

/// Pantalla de partida (plan §8.4). Crea el [GameProvider] scoped: se destruye
/// al salir (plan §6.3 regla 5).
class GameScreen extends StatelessWidget {
  const GameScreen({super.key, required this.args});

  final GameArgs args;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GameProvider>(
      create: (ctx) => GameProvider(
        config: args.config,
        difficulty: args.difficulty,
        records: ctx.read<RecordsRepository>(),
        savegame: ctx.read<SavegameRepository>(),
        resumeWaves: args.resumeWaves,
        invertControls: ctx.read<SettingsRepository>().invertControls,
      ),
      child: const _GameView(),
    );
  }
}

class _GameView extends StatelessWidget {
  const _GameView();

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final status = gp.status;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Back físico: pausar si se juega; si no, salir (plan §4.2).
        if (status == GameStatus.playing) {
          gp.pause();
        } else {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  GameTopHud(onPause: gp.pause),
                  const GameComboBar(),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: BoardWidget(),
                    ),
                  ),
                  const GameActionBar(),
                ],
              ),
              if (status == GameStatus.paused)
                PauseOverlay(
                  onResume: gp.resume,
                  onRestart: gp.restart,
                  onExit: () => Navigator.of(context).pop(),
                ),
              if (gp.awaitingUpgrade)
                WaveUpgradeOverlay(
                  choices: gp.upgradeChoices,
                  onChoose: gp.chooseUpgrade,
                ),
              if (gp.waveWarningActive) const _WaveWarningBanner(),
              if (status == GameStatus.won || status == GameStatus.lost)
                ResultOverlay(
                  won: status == GameStatus.won,
                  elapsed: gp.elapsed.value,
                  isNewRecord: gp.isNewRecord,
                  isBlitz: gp.isBlitz,
                  blitzScore: gp.blitzScore,
                  blitzBoards: gp.blitzBoards,
                  timeUp: gp.timeUp,
                  isWaves: gp.isWaves,
                  wavesReached: gp.wave,
                  wavesScore: gp.wavesScore,
                  onPlayAgain: gp.restart,
                  onExit: () => Navigator.of(context).pop(),
                ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

/// Aviso transitorio de "minas nuevas" al activarse el modificador de minas con
/// retardo (plan §2.5).
class _WaveWarningBanner extends StatelessWidget {
  const _WaveWarningBanner();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l = AppLocalizations.of(context)!;
    return Positioned(
      top: 70,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: palette.danger.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: palette.danger.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  l.waveNewMines,
                  style: TextStyle(
                    color: palette.onAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1, end: 1.06, duration: 400.ms),
        ),
      ),
    );
  }
}

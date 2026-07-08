import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../data/repositories/records_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/models/game_status.dart';
import '../../providers/game_provider.dart';
import '../overlays/pause_overlay.dart';
import '../overlays/result_overlay.dart';
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
              if (status == GameStatus.won || status == GameStatus.lost)
                ResultOverlay(
                  won: status == GameStatus.won,
                  elapsed: gp.elapsed.value,
                  isNewRecord: gp.isNewRecord,
                  isBlitz: gp.isBlitz,
                  blitzScore: gp.blitzScore,
                  blitzBoards: gp.blitzBoards,
                  timeUp: gp.timeUp,
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

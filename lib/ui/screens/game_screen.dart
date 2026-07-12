import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../data/repositories/records_repository.dart';
import '../../data/repositories/savegame_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/engine/economy_engine.dart';
import '../../domain/models/game_mode.dart';
import '../../domain/models/game_outcome.dart';
import '../../domain/models/game_status.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/achievements_provider.dart';
import '../../providers/daily_provider.dart';
import '../../providers/economy_provider.dart';
import '../../providers/game_provider.dart';
import '../overlays/pause_overlay.dart';
import '../overlays/result_overlay.dart';
import '../overlays/wave_upgrade_overlay.dart';
import '../widgets/board/board_widget.dart';
import '../widgets/common/app_background.dart';
import '../widgets/hud/game_hud.dart';

/// Recompensas mostradas en el resultado tras terminar (Fase 5).
class _Rewards {
  const _Rewards({required this.coins, required this.unlocked});
  final int coins;
  final List<String> unlocked;
}

/// Pantalla de partida (plan §8.4). Crea el [GameProvider] scoped: se destruye
/// al salir (plan §6.3 regla 5). Al terminar otorga monedas/logros (Fase 5).
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.args});

  final GameArgs args;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  /// Recompensas de la última partida terminada; se llena de forma asíncrona
  /// tras otorgar monedas/logros y lo escucha el [ResultOverlay].
  final ValueNotifier<_Rewards?> _rewards = ValueNotifier(null);

  /// Cargas iniciales extra de consumibles de la tienda (§3.1), leídas antes de
  /// crear el `GameProvider` y consumidas del inventario.
  int _startingBonus = 0;

  @override
  void initState() {
    super.initState();
    final economy = context.read<EconomyProvider>();
    final mode = widget.args.config.mode;
    _startingBonus = economy.startingChargesAvailable(mode);
    if (_startingBonus > 0) {
      // Consumir del inventario (fire-and-forget): se aplican como cargas base.
      economy.takeStartingCharges(mode);
    }
  }

  @override
  void dispose() {
    _rewards.dispose();
    super.dispose();
  }

  /// Otorga monedas (partida + racha diaria) y evalúa logros al terminar.
  Future<void> _handleGameEnd(BuildContext ctx, GameOutcome o) async {
    // Capturar dependencias antes de cualquier await (evita usar context tras
    // el gap asíncrono).
    final economy = ctx.read<EconomyProvider>();
    final achievements = ctx.read<AchievementsProvider>();
    final daily = ctx.read<DailyProvider>();
    final locale = AppLocalizations.of(ctx)!.localeName;
    const engine = EconomyEngine();

    var coins = engine.coinsForOutcome(o);
    if (o.isDaily && o.isSuccess) {
      final streak = await daily.markCompleted();
      coins += engine.streakReward(streak);
    }
    if (coins > 0) await economy.addCoins(coins);

    final unlock = await achievements.registerOutcome(o);
    if (unlock.coins > 0) await economy.addCoins(unlock.coins);

    _rewards.value = _Rewards(
      coins: coins + unlock.coins,
      unlocked: [for (final a in unlock.achievements) a.name(locale)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final mode = args.config.mode;
    return ChangeNotifierProvider<GameProvider>(
      create: (ctx) => GameProvider(
        config: args.config,
        difficulty: args.difficulty,
        records: ctx.read<RecordsRepository>(),
        savegame: ctx.read<SavegameRepository>(),
        resumeWaves: args.resumeWaves,
        isDaily: args.isDaily,
        bonusFlashlight: mode == GameMode.fog ? _startingBonus : 0,
        bonusFreezer: mode == GameMode.blitz ? _startingBonus : 0,
        bonusScanner: mode == GameMode.liar ? _startingBonus : 0,
        onGameEnd: (o) => _handleGameEnd(ctx, o),
        invertControls: ctx.read<SettingsRepository>().invertControls,
      ),
      child: _GameView(rewards: _rewards),
    );
  }
}

class _GameView extends StatelessWidget {
  const _GameView({required this.rewards});

  final ValueNotifier<_Rewards?> rewards;

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
                ValueListenableBuilder<_Rewards?>(
                  valueListenable: rewards,
                  builder: (context, reward, _) => ResultOverlay(
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
                    coinsEarned: reward?.coins ?? 0,
                    unlockedAchievements: reward?.unlocked ?? const [],
                    onPlayAgain: () {
                      rewards.value = null;
                      gp.restart();
                    },
                    onExit: () => Navigator.of(context).pop(),
                  ),
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

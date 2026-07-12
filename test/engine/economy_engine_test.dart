import 'package:flutter_test/flutter_test.dart';
import 'package:minex/core/constants/difficulty.dart';
import 'package:minex/domain/engine/economy_engine.dart';
import 'package:minex/domain/models/game_mode.dart';
import 'package:minex/domain/models/game_outcome.dart';

void main() {
  const engine = EconomyEngine();

  GameOutcome outcome(
    GameMode mode, {
    Difficulty difficulty = Difficulty.easy,
    bool won = true,
    int blitzScore = 0,
    int blitzBoards = 0,
    int wavesReached = 0,
    bool isDaily = false,
  }) =>
      GameOutcome(
        mode: mode,
        difficulty: difficulty,
        won: won,
        elapsed: Duration.zero,
        blitzScore: blitzScore,
        blitzBoards: blitzBoards,
        wavesReached: wavesReached,
        isDaily: isDaily,
      );

  group('coinsForOutcome', () {
    test('clásico da base por dificultad al ganar y 0 al perder', () {
      expect(engine.coinsForOutcome(outcome(GameMode.classic)), 10);
      expect(
        engine.coinsForOutcome(
            outcome(GameMode.classic, difficulty: Difficulty.expert)),
        70,
      );
      expect(
        engine.coinsForOutcome(outcome(GameMode.classic, won: false)),
        0,
      );
    });

    test('niebla ×1.5 y mentiroso ×2 sobre la base', () {
      // medio = 20 → niebla 30, mentiroso 40
      expect(
        engine.coinsForOutcome(
            outcome(GameMode.fog, difficulty: Difficulty.medium)),
        30,
      );
      expect(
        engine.coinsForOutcome(
            outcome(GameMode.liar, difficulty: Difficulty.medium)),
        40,
      );
    });

    test('blitz por tableros + fracción del puntaje', () {
      // 3 tableros * 8 + 100/20 = 24 + 5 = 29
      expect(
        engine.coinsForOutcome(
            outcome(GameMode.blitz, won: false, blitzBoards: 3, blitzScore: 100)),
        29,
      );
    });

    test('oleadas por oleadas alcanzadas aunque pierda', () {
      expect(
        engine.coinsForOutcome(
            outcome(GameMode.waves, won: false, wavesReached: 4)),
        20,
      );
    });

    test('el Reto Diario duplica el total', () {
      expect(
        engine.coinsForOutcome(outcome(GameMode.classic, isDaily: true)),
        20,
      );
    });
  });

  group('streakReward', () {
    test('escala dentro de la semana y da cofre al 7º día', () {
      expect(engine.streakReward(0), 0);
      expect(engine.streakReward(1), 10);
      expect(engine.streakReward(6), 35);
      expect(engine.streakReward(7), 100);
      expect(engine.streakReward(8), 10);
      expect(engine.streakReward(14), 100);
    });
  });
}
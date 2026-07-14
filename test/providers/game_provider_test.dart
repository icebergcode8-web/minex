import 'package:flutter_test/flutter_test.dart';
import 'package:minex/core/constants/difficulty.dart';
import 'package:minex/data/local/hive_service.dart';
import 'package:minex/data/repositories/records_repository.dart';
import 'package:minex/data/repositories/savegame_repository.dart';
import 'package:minex/domain/models/game_config.dart';
import 'package:minex/domain/models/game_mode.dart';
import 'package:minex/domain/models/game_outcome.dart';
import 'package:minex/domain/models/game_status.dart';
import 'package:minex/domain/models/wave_modifier.dart';
import 'package:minex/providers/game_provider.dart';

/// Savegame en memoria: evita depender de Hive en los tests.
class FakeSavegameRepository extends SavegameRepository {
  FakeSavegameRepository() : super(HiveService());
  Map<String, dynamic>? _waves;

  @override
  bool get hasWaves => _waves != null;

  @override
  Map<String, dynamic>? loadWaves() => _waves;

  @override
  Future<void> saveWaves(Map<String, dynamic> state) async {
    _waves = Map<String, dynamic>.of(state);
  }

  @override
  Future<void> clearWaves() async {
    _waves = null;
  }
}

/// Records en memoria: evita depender de Hive en los tests del provider.
class FakeRecordsRepository extends RecordsRepository {
  FakeRecordsRepository() : super(HiveService());
  int? _best;
  int _blitzBest = 0;

  @override
  int? bestTimeMs(Difficulty d) => _best;

  @override
  Future<bool> recordGame({
    required Difficulty difficulty,
    required bool won,
    required Duration elapsed,
  }) async {
    if (won && (_best == null || elapsed.inMilliseconds < _best!)) {
      _best = elapsed.inMilliseconds;
      return true;
    }
    return false;
  }

  @override
  int get blitzBestScore => _blitzBest;

  @override
  Future<bool> recordBlitz(int score) async {
    if (score > _blitzBest) {
      _blitzBest = score;
      return true;
    }
    return false;
  }

  int _wavesBest = 0;

  @override
  int get wavesBestScore => _wavesBest;

  @override
  Future<bool> recordWaves(int score) async {
    if (score > _wavesBest) {
      _wavesBest = score;
      return true;
    }
    return false;
  }
}

void main() {
  const config = GameConfig(
    mode: GameMode.classic,
    rows: 6,
    cols: 6,
    mines: 4,
    seed: 123,
  );

  GameProvider newProvider() => GameProvider(
        config: config,
        difficulty: Difficulty.easy,
        records: FakeRecordsRepository(),
      );

  test('empieza en idle sin minas colocadas hasta el primer toque', () {
    final gp = newProvider();
    expect(gp.status, GameStatus.idle);
    // Ninguna celda tiene mina todavía.
    expect(gp.board.cells.where((c) => c.hasMine), isEmpty);
    gp.dispose();
  });

  test('el primer toque genera el tablero y arranca la partida (safe)', () {
    final gp = newProvider();
    gp.onTap(3, 3);
    expect(gp.status, isNot(GameStatus.idle));
    // La celda tocada quedó revelada y no era mina (primer clic seguro).
    expect(gp.board.cellAt(3, 3).hasMine, isFalse);
    expect(gp.board.cellAt(3, 3).isRevealed, isTrue);
    expect(gp.board.cells.where((c) => c.hasMine).length, 4);
    gp.dispose();
  });

  test('revelar todas las celdas seguras gana la partida', () {
    final gp = newProvider();
    gp.onTap(0, 0); // genera tablero
    for (final cell in gp.board.cells) {
      if (!cell.hasMine && !cell.isRevealed) {
        gp.onTap(cell.row, cell.col);
      }
    }
    expect(gp.status, GameStatus.won);
    gp.dispose();
  });

  test('emite GameOutcome al terminar (economía, Fase 5)', () {
    GameOutcome? emitted;
    final gp = GameProvider(
      config: config,
      difficulty: Difficulty.easy,
      records: FakeRecordsRepository(),
      isDaily: true,
      onGameEnd: (o) => emitted = o,
    );
    gp.onTap(0, 0);
    for (final cell in gp.board.cells) {
      if (!cell.hasMine && !cell.isRevealed) {
        gp.onTap(cell.row, cell.col);
      }
    }
    expect(gp.status, GameStatus.won);
    expect(emitted, isNotNull);
    expect(emitted!.won, isTrue);
    expect(emitted!.mode, GameMode.classic);
    expect(emitted!.difficulty, Difficulty.easy);
    expect(emitted!.isDaily, isTrue);
    expect(emitted!.isSuccess, isTrue);
    gp.dispose();
  });

  test('tocar una mina pierde la partida y marca la celda explotada', () {
    // Tablero denso: el primer toque no despeja todo, así queda mina por tocar.
    final gp = GameProvider(
      config: const GameConfig(
        mode: GameMode.classic,
        rows: 10,
        cols: 10,
        mines: 30,
        seed: 7,
      ),
      difficulty: Difficulty.easy,
      records: FakeRecordsRepository(),
    );
    gp.onTap(0, 0); // genera tablero (celda segura)
    expect(gp.status, GameStatus.playing, reason: 'no debe ganar al instante');
    final mine = gp.board.cells.firstWhere((c) => c.hasMine);
    gp.onTap(mine.row, mine.col);
    expect(gp.status, GameStatus.lost);
    expect(gp.explodedCell, isNotNull);
    gp.dispose();
  });

  test('en modo bandera el tap marca en vez de revelar', () {
    final gp = newProvider();
    gp.onTap(2, 2); // genera y juega
    gp.toggleFlagMode();
    expect(gp.flagMode, isTrue);
    gp.onTap(0, 0);
    expect(gp.board.cellAt(0, 0).isFlagged, isTrue);
    expect(gp.board.cellAt(0, 0).isRevealed, isFalse);
    gp.dispose();
  });

  test('pausar y reanudar cambia el estado', () {
    final gp = newProvider();
    gp.onTap(2, 2);
    gp.pause();
    expect(gp.status, GameStatus.paused);
    gp.resume();
    expect(gp.status, GameStatus.playing);
    gp.dispose();
  });

  group('Blitz (§2.3)', () {
    GameProvider newBlitz() => GameProvider(
          config: blitzConfig(seed: 42),
          difficulty: Difficulty.easy,
          records: FakeRecordsRepository(),
        );

    test('arranca con cuenta atrás de 60s y sin puntaje', () {
      final gp = newBlitz();
      expect(gp.isBlitz, isTrue);
      expect(gp.status, GameStatus.idle);
      expect(gp.elapsed.value, const Duration(seconds: 60));
      expect(gp.blitzScore, 0);
      gp.dispose();
    });

    test('completar el tablero NO gana: avanza al siguiente y suma marcador',
        () {
      final gp = newBlitz();
      gp.onTap(0, 0); // genera y arranca
      // Revelar todas las celdas seguras del tablero actual.
      final board = gp.board;
      for (final cell in board.cells) {
        if (!cell.hasMine && !cell.isRevealed && gp.blitzBoards == 0) {
          gp.onTap(cell.row, cell.col);
        }
      }
      expect(gp.blitzBoards, 1, reason: 'debe avanzar de tablero');
      expect(gp.status, GameStatus.playing, reason: 'no termina la partida');
      expect(gp.blitzScore, greaterThan(0));
      gp.dispose();
    });

    test('tocar una mina termina la partida (sin timeUp)', () {
      final gp = newBlitz();
      gp.onTap(0, 0);
      expect(gp.status, GameStatus.playing);
      final mine = gp.board.cells.firstWhere((c) => c.hasMine);
      gp.onTap(mine.row, mine.col);
      expect(gp.status, GameStatus.lost);
      expect(gp.timeUp, isFalse);
      expect(gp.explodedCell, isNotNull);
      gp.dispose();
    });

    test('el Congelador suma tiempo y consume carga', () {
      final gp = newBlitz();
      gp.onTap(0, 0); // playing
      expect(gp.freezerCharges, 1);
      gp.useFreezer();
      expect(gp.freezerCharges, 0);
      // Restante por encima de 60s tras el bono de 10s (menos lo ya corrido).
      expect(gp.elapsed.value.inSeconds, greaterThanOrEqualTo(60));
      gp.dispose();
    });
  });

  group('Niebla (§2.2)', () {
    GameProvider newFog(FakeRecordsRepository records) => GameProvider(
          config: fogConfig(Difficulty.easy, seed: 99),
          difficulty: Difficulty.easy,
          records: records,
        );

    test('el foco se fija en la celda tocada al revelar', () {
      final gp = newFog(FakeRecordsRepository());
      expect(gp.isFog, isTrue);
      expect(gp.fogFocusRow, -1); // sin foco antes del primer toque
      gp.onTap(4, 4);
      expect(gp.fogFocusRow, 4);
      expect(gp.fogFocusCol, 4);
      gp.dispose();
    });

    test('la Linterna consume carga y fija una ventana futura', () {
      final gp = newFog(FakeRecordsRepository());
      gp.onTap(0, 0); // playing
      expect(gp.flashlightCharges, 1);
      final before = DateTime.now().millisecondsSinceEpoch;
      gp.useFlashlight();
      expect(gp.flashlightCharges, 0);
      expect(gp.flashlightUntilEpochMs, greaterThan(before));
      gp.dispose();
    });

    test('ganar en Niebla NO escribe récords del clásico', () {
      final records = FakeRecordsRepository();
      final gp = newFog(records);
      gp.onTap(0, 0);
      for (final cell in gp.board.cells) {
        if (!cell.hasMine && !cell.isRevealed) {
          gp.onTap(cell.row, cell.col);
        }
      }
      expect(gp.status, GameStatus.won);
      // El clásico no fue tocado: sin mejor tiempo registrado.
      expect(records.bestTimeMs(Difficulty.easy), isNull);
      gp.dispose();
    });
  });

  group('Mentiroso (§2.4)', () {
    GameProvider newLiar() => GameProvider(
          config: liarConfig(Difficulty.medium, seed: 5),
          difficulty: Difficulty.medium,
          records: FakeRecordsRepository(),
        );

    test('generar el tablero aplica mentiras (±1 del real)', () {
      final gp = newLiar();
      expect(gp.isLiar, isTrue);
      gp.onTap(0, 0);
      final liars = gp.board.cells.where((c) => c.isLiar).toList();
      expect(liars, isNotEmpty);
      for (final c in liars) {
        expect((c.displayedNumber! - c.adjacentMines).abs(), 1);
      }
      gp.dispose();
    });

    test('el Escáner corrige una celda mentirosa y consume carga', () {
      final gp = newLiar();
      gp.onTap(0, 0);
      // Revelar celdas seguras hasta que una mentirosa quede a la vista.
      int? lr, lc;
      for (final cell in gp.board.cells.toList()) {
        if (!cell.hasMine && !cell.isRevealed) {
          gp.onTap(cell.row, cell.col);
        }
        final revealed =
            gp.board.cells.where((c) => c.isRevealed && c.isLiar);
        if (revealed.isNotEmpty) {
          lr = revealed.first.row;
          lc = revealed.first.col;
          break;
        }
        if (gp.status != GameStatus.playing) break;
      }
      expect(lr, isNotNull, reason: 'debe haber una mentirosa revelada');
      expect(gp.status, GameStatus.playing);
      expect(gp.scannerCharges, 3);

      gp.toggleScanner();
      expect(gp.scannerMode, isTrue);
      gp.onTap(lr!, lc!); // escanea
      expect(gp.scannerCharges, 2);
      expect(gp.scannerMode, isFalse);
      final cell = gp.board.cellAt(lr, lc);
      expect(cell.isLiar, isFalse);
      expect(cell.displayedNumber, cell.adjacentMines); // ya dice la verdad
      gp.dispose();
    });
  });

  group('Oleadas (§2.5)', () {
    GameProvider newWaves({
      FakeSavegameRepository? save,
      bool resume = false,
      WaveModifier? modifier,
    }) =>
        GameProvider(
          config: wavesConfig(),
          difficulty: Difficulty.easy,
          records: FakeRecordsRepository(),
          savegame: save ?? FakeSavegameRepository(),
          resumeWaves: resume,
          debugForceModifier: modifier,
        );

    test('arranca en oleada 1, 7×7, 3 vidas y jugando', () {
      final gp = newWaves();
      expect(gp.isWaves, isTrue);
      expect(gp.wave, 1);
      expect(gp.lives, 3);
      expect(gp.board.rows, 7);
      expect(gp.board.cols, 7);
      expect(gp.status, GameStatus.playing);
      gp.dispose();
    });

    test('completar la oleada ofrece mejoras y sumar puntaje; elegir avanza',
        () {
      final gp = newWaves();
      // Revelar todas las celdas seguras del tablero.
      while (!gp.awaitingUpgrade) {
        final remaining = gp.board.cells
            .where((c) => !c.hasMine && !c.isRevealed)
            .toList();
        if (remaining.isEmpty) break;
        gp.onTap(remaining.first.row, remaining.first.col);
      }
      expect(gp.awaitingUpgrade, isTrue);
      expect(gp.upgradeChoices.length, 3);
      expect(gp.wavesScore, 1 * 49); // oleada 1 × 49 celdas

      gp.chooseUpgrade(gp.upgradeChoices.first);
      expect(gp.awaitingUpgrade, isFalse);
      expect(gp.wave, 2);
      expect(gp.board.rows, 8); // +1 fila en la oleada 2
      gp.dispose();
    });

    test('tocar una mina cuesta una vida y la neutraliza (no game over)', () {
      final gp = newWaves();
      final mine = gp.board.cells.firstWhere((c) => c.hasMine);
      gp.onTap(mine.row, mine.col);
      expect(gp.lives, 2);
      expect(gp.status, GameStatus.playing);
      expect(gp.board.cellAt(mine.row, mine.col).isFlagged, isTrue);
      gp.dispose();
    });

    test('agotar las vidas es game over y limpia el savegame', () {
      final save = FakeSavegameRepository();
      final gp = newWaves(save: save);
      final mines =
          gp.board.cells.where((c) => c.hasMine).take(3).toList();
      for (final m in mines) {
        gp.onTap(m.row, m.col);
      }
      expect(gp.lives, 0);
      expect(gp.status, GameStatus.lost);
      expect(save.hasWaves, isFalse); // run terminada → sin partida guardada
      gp.dispose();
    });

    test('reanuda la run guardada (solo progresión, sin tablero) regenera', () {
      final save = FakeSavegameRepository();
      save.saveWaves({
        'wave': 4,
        'lives': 2,
        'score': 200,
        'shield': 1,
        'radar': true,
        'vision': false,
      });
      final gp = newWaves(save: save, resume: true);
      expect(gp.wave, 4);
      expect(gp.lives, 2);
      expect(gp.wavesScore, 200);
      expect(gp.shieldCharges, 1);
      expect(gp.board.rows, 9); // boardFor(4) = 9×8
      gp.dispose();
    });

    test('reanuda el tablero EXACTO tras cerrar la app a media oleada', () {
      // 1ª sesión: jugar unos toques en una oleada con modificador conocido.
      final save = FakeSavegameRepository();
      final gp1 = newWaves(save: save, modifier: WaveModifier.chainedMines);
      // Revelar algunas celdas seguras (sin completar la oleada).
      final safe = gp1.board.cells
          .where((c) => !c.hasMine && !c.isRevealed)
          .take(3)
          .toList();
      for (final c in safe) {
        gp1.onTap(c.row, c.col);
      }
      // Poner una bandera en una mina conocida.
      final mine = gp1.board.cells.firstWhere((c) => c.hasMine);
      gp1.toggleFlagMode();
      gp1.onTap(mine.row, mine.col);
      // Fotografiar el estado exacto antes de "cerrar".
      final revealedBefore = {
        for (final c in gp1.board.cells)
          if (c.isRevealed) '${c.row},${c.col}',
      };
      final flaggedBefore = {
        for (final c in gp1.board.cells)
          if (c.isFlagged) '${c.row},${c.col}',
      };
      final mineCountBefore =
          gp1.board.cells.where((c) => c.hasMine).length;
      gp1.dispose();

      // 2ª sesión: reanudar desde el mismo savegame.
      final gp2 = newWaves(save: save, resume: true);
      expect(gp2.status, GameStatus.playing);
      expect(gp2.currentModifier, WaveModifier.chainedMines);
      expect(gp2.board.cells.where((c) => c.hasMine).length, mineCountBefore);
      final revealedAfter = {
        for (final c in gp2.board.cells)
          if (c.isRevealed) '${c.row},${c.col}',
      };
      final flaggedAfter = {
        for (final c in gp2.board.cells)
          if (c.isFlagged) '${c.row},${c.col}',
      };
      expect(revealedAfter, revealedBefore); // mismas celdas reveladas
      expect(flaggedAfter, flaggedBefore); // mismas banderas
      gp2.dispose();
    });

    test('reanuda ofreciendo mejora si se cerró en la pantalla de mejora', () {
      final save = FakeSavegameRepository();
      final gp1 = newWaves(save: save);
      while (!gp1.awaitingUpgrade) {
        final remaining = gp1.board.cells
            .where((c) => !c.hasMine && !c.isRevealed)
            .toList();
        if (remaining.isEmpty) break;
        gp1.onTap(remaining.first.row, remaining.first.col);
      }
      expect(gp1.awaitingUpgrade, isTrue);
      final choicesBefore =
          gp1.upgradeChoices.map((u) => u.name).toList();
      gp1.dispose();

      final gp2 = newWaves(save: save, resume: true);
      expect(gp2.awaitingUpgrade, isTrue);
      expect(gp2.upgradeChoices.map((u) => u.name).toList(), choicesBefore);
      gp2.dispose();
    });

    group('modificadores (§2.5)', () {
      test('niebla parcial activa la visibilidad limitada', () {
        final gp = newWaves(modifier: WaveModifier.partialFog);
        expect(gp.currentModifier, WaveModifier.partialFog);
        expect(gp.wavePartialFog, isTrue);
        expect(gp.fogActive, isTrue);
        expect(gp.fogFocusRow, greaterThanOrEqualTo(0)); // foco en el centro
        gp.dispose();
      });

      test('números mentirosos marca celdas del tablero', () {
        final gp = newWaves(modifier: WaveModifier.liarNumbers);
        expect(gp.currentModifier, WaveModifier.liarNumbers);
        expect(gp.board.cells.any((c) => c.isLiar), isTrue);
        gp.dispose();
      });

      test('minas encadenadas mantiene el número de minas de la oleada', () {
        final gp = newWaves(modifier: WaveModifier.chainedMines);
        expect(gp.currentModifier, WaveModifier.chainedMines);
        expect(gp.board.cells.where((c) => c.hasMine).length, 6);
        gp.dispose();
      });

      test('minas con retardo inyecta 3 minas a mitad de oleada + aviso', () {
        final gp = newWaves(modifier: WaveModifier.delayedMines);
        final initial = gp.board.cells.where((c) => c.hasMine).length;
        var injected = false;
        while (!gp.awaitingUpgrade) {
          final remaining = gp.board.cells
              .where((c) => !c.hasMine && !c.isRevealed)
              .toList();
          if (remaining.isEmpty) break;
          gp.onTap(remaining.first.row, remaining.first.col);
          if (gp.board.cells.where((c) => c.hasMine).length > initial) {
            injected = true;
            break;
          }
        }
        expect(injected, isTrue);
        // Inyecta hasta 3 minas; si la cascada dejó pocas celdas ocultas,
        // convierte las que haya disponibles (tablero 7×7 sin semilla fija).
        final after = gp.board.cells.where((c) => c.hasMine).length;
        expect(after, greaterThan(initial));
        expect(after, lessThanOrEqualTo(initial + 3));
        expect(gp.waveWarningActive, isTrue);
        gp.dispose();
      });
    });
  });

  group('Torre 3D (§2.6)', () {
    GameProvider newTower() => GameProvider(
          config: towerConfig(Difficulty.easy, seed: 123), // Fácil = 3 capas
          difficulty: Difficulty.easy,
          records: FakeRecordsRepository(),
        );

    /// Revela todas las celdas seguras de la capa activa actual.
    void clearActiveLayer(GameProvider gp) {
      final board = gp.board;
      for (final c in board.cells) {
        if (!c.hasMine && !c.isRevealed && gp.status == GameStatus.playing) {
          gp.onTap(c.row, c.col);
        }
      }
    }

    test('arranca en la cima con el centro revelado y jugando', () {
      final gp = newTower();
      expect(gp.isTower, isTrue);
      expect(gp.tower, isNotNull);
      expect(gp.towerLayerCount, 3);
      expect(gp.towerLayer, 1); // capa 1/3 = cima
      expect(gp.status, GameStatus.playing);
      expect(gp.board.cellAt(4, 4).isRevealed, isTrue); // foothold central
      gp.dispose();
    });

    test('completar una capa desciende a la siguiente', () {
      final gp = newTower();
      final startActive = gp.tower!.activeLayer;
      clearActiveLayer(gp);
      // Aún jugando (quedan capas) y la capa activa descendió.
      expect(gp.status, GameStatus.playing);
      expect(gp.tower!.activeLayer, startActive - 1);
      expect(gp.towerLayer, 2); // capa 2/3
      gp.dispose();
    });

    test('completar todas las capas gana la torre', () {
      final gp = newTower();
      var guard = 0;
      while (gp.status == GameStatus.playing && guard++ < 10) {
        clearActiveLayer(gp);
      }
      expect(gp.status, GameStatus.won);
      gp.dispose();
    });

    test('tocar una mina termina la partida (derrota)', () {
      final gp = newTower();
      final mine = gp.board.cells.firstWhere((c) => c.hasMine);
      gp.onTap(mine.row, mine.col);
      expect(gp.status, GameStatus.lost);
      expect(gp.explodedCell, isNotNull);
      gp.dispose();
    });
  });
}

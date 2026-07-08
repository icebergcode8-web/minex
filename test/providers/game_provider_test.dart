import 'package:flutter_test/flutter_test.dart';
import 'package:minex/core/constants/difficulty.dart';
import 'package:minex/data/local/hive_service.dart';
import 'package:minex/data/repositories/records_repository.dart';
import 'package:minex/domain/models/game_config.dart';
import 'package:minex/domain/models/game_mode.dart';
import 'package:minex/domain/models/game_status.dart';
import 'package:minex/providers/game_provider.dart';

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
}

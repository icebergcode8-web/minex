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
}

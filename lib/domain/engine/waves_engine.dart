import 'dart:math';

import '../models/board.dart';
import '../models/cell.dart';
import '../models/wave_modifier.dart';
import 'board_generator.dart';

/// Mejoras roguelike ofrecidas al completar una oleada (plan §2.5).
enum WaveUpgrade {
  /// +1 vida (hasta el máximo).
  extraLife,

  /// El próximo error no cuesta vida (1 carga acumulable).
  shield,

  /// Marca 1 mina al azar con bandera al inicio de cada oleada.
  radar,

  /// Revela una zona segura de 3×3 al inicio de la siguiente oleada.
  vision,

  /// +1 carga de escudo (representa "+1 carga de un ítem" en Oleadas).
  itemCharge,
}

/// Especificación del tablero de una oleada.
class WaveBoardSpec {
  const WaveBoardSpec({
    required this.rows,
    required this.cols,
    required this.mines,
  });

  final int rows;
  final int cols;
  final int mines;

  int get cells => rows * cols;
}

/// Lógica pura del modo Oleadas (plan §2.5). **Sin Flutter** (CLAUDE.md): el
/// crecimiento del tablero, el puntaje y el sorteo de mejoras son deterministas
/// y testeables sin emulador. El estado mutable de la partida vive en el
/// provider; aquí solo hay reglas.
class WavesEngine {
  const WavesEngine({
    this.startRows = 7,
    this.startCols = 7,
    this.startMines = 6,
    this.densityStep = 0.005, // +0.5% de densidad por oleada
    this.maxLives = 5,
    this.startLives = 3,
    this.modifiersFromWave = 5,
  });

  final int startRows;
  final int startCols;
  final int startMines;
  final double densityStep;
  final int maxLives;
  final int startLives;
  final int modifiersFromWave;

  double get _baseDensity => startMines / (startRows * startCols);

  /// Tablero de la oleada [wave] (1-based). Cada oleada suma +1 alternando fila
  /// y columna, y la densidad sube [densityStep]; las minas se recalculan.
  WaveBoardSpec boardFor(int wave) {
    assert(wave >= 1);
    var rows = startRows;
    var cols = startCols;
    // Pasos de crecimiento: en la oleada w>1 se ha crecido w-1 veces, alternando
    // fila (pasos impares) y columna (pasos pares).
    for (var step = 1; step < wave; step++) {
      if (step.isOdd) {
        rows++;
      } else {
        cols++;
      }
    }
    final density = _baseDensity + densityStep * (wave - 1);
    // Dejar al menos 9 celdas seguras (zona del primer clic).
    final maxMines = (rows * cols - 9).clamp(1, rows * cols);
    final mines = (rows * cols * density).round().clamp(1, maxMines);
    return WaveBoardSpec(rows: rows, cols: cols, mines: mines);
  }

  /// Puntaje al completar la oleada [wave] con un tablero de [cells] celdas
  /// (plan §2.5: puntaje = oleadas × celdas; multiplicadores en Fase 5).
  int waveScore(int wave, int cells) => wave * cells;

  /// Ofrece 3 mejoras distintas del pool (§2.5). [available] permite filtrar
  /// mejoras ya inútiles (p. ej. vida al máximo); si quedan menos de 3, devuelve
  /// las que haya.
  List<WaveUpgrade> rollUpgrades(Random rng, {Set<WaveUpgrade>? available}) {
    final pool = (available?.toList() ?? WaveUpgrade.values.toList())
      ..shuffle(rng);
    return pool.take(3).toList();
  }

  /// Los modificadores de oleada se activan a partir de [modifiersFromWave].
  bool modifiersActiveAt(int wave) => wave >= modifiersFromWave;

  /// Modificador aleatorio para la oleada [wave], o `null` si aún no aplican
  /// (§2.5, línea de modificadores). Determinista con el [rng] dado.
  WaveModifier? modifierFor(int wave, Random rng) {
    if (!modifiersActiveAt(wave)) return null;
    final all = WaveModifier.values;
    return all[rng.nextInt(all.length)];
  }

  /// Fracción de números que mienten con el modificador [WaveModifier.liarNumbers]
  /// (§2.5: 5%).
  double get liarModifierRatio => 0.05;

  /// Cuántas minas nuevas aparecen con [WaveModifier.delayedMines] (§2.5: 3).
  int get delayedMinesCount => 3;

  /// Inyecta [count] minas nuevas en celdas ocultas, no marcadas y sin mina de
  /// [board], recalcula la adyacencia y devuelve las celdas afectadas
  /// (modificador "minas con retardo", §2.5). Determinista con [rng].
  List<Cell> injectMines(Board board, int count, Random rng) {
    final candidates = [
      for (final c in board.cells)
        if (!c.hasMine && !c.isRevealed && !c.isFlagged) c,
    ]..shuffle(rng);
    final injected = <Cell>[];
    for (var i = 0; i < count && i < candidates.length; i++) {
      candidates[i].hasMine = true;
      injected.add(candidates[i]);
    }
    computeAdjacency(board);
    return injected;
  }
}
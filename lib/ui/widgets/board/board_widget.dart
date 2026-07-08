import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/haptics/haptics_service.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/board.dart';
import '../../../domain/models/cell.dart';
import '../../../domain/models/game_status.dart';
import '../../../providers/game_provider.dart';

/// Renderiza el tablero en un solo `CustomPaint` (plan §5.2) y traduce los
/// gestos a acciones del [GameProvider]. Envuelto en [InteractiveViewer] para
/// zoom/paneo en tableros grandes y en [RepaintBoundary] para aislar repintados.
///
/// Concentra el "juice" del tablero (plan §5.2): flip al revelar, cascada en
/// ondas del flood fill, bandera con bounce, shake + onda de explosión y wave de
/// brillo al ganar. Dispara háptica y SFX en cada evento.
class BoardWidget extends StatefulWidget {
  const BoardWidget({super.key});

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget>
    with TickerProviderStateMixin {
  /// Duración del "flip" de cada celda al revelarse.
  static const _revealMs = 150.0;

  /// Delay incremental por anillo BFS: el efecto dominó (plan §5.2).
  static const _ringDelayMs = 18.0;

  /// Duración del bounce de la bandera.
  static const _flagMs = 220.0;

  /// Duración de la wave de victoria recorriendo el tablero.
  static const _winMs = 900.0;

  /// Reloj monótono (nunca se reinicia) que sirve de base temporal.
  final Stopwatch _clock = Stopwatch()..start();

  /// Notifica al painter que debe repintar cada frame de animación.
  final ValueNotifier<int> _frame = ValueNotifier(0);

  late final Ticker _ticker = createTicker((_) {
    _frame.value++;
    if (!_isAnimating) _ticker.stop();
  });

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  /// Inicio de animación de revelado por índice de celda (`row*cols+col`).
  final Map<int, double> _revealStart = {};

  /// Inicio del bounce de bandera por índice de celda.
  final Map<int, double> _flagStart = {};

  /// Índices actualmente con bandera, para detectar banderas nuevas.
  final Set<int> _flaggedSnapshot = {};

  int _lastBatch = 0;
  int _lastGeneration = 0;
  GameStatus _lastStatus = GameStatus.idle;
  double _explodeStartMs = -1;
  double _winStartMs = -1;

  double get _now => _clock.elapsedMilliseconds.toDouble();

  // Servicios de feedback (se leen sin escuchar).
  HapticsService get _haptics => context.read<HapticsService>();
  AudioService get _audio => context.read<AudioService>();

  bool get _isAnimating {
    if (_shake.isAnimating) return true;
    if (_explodeStartMs >= 0 && _now - _explodeStartMs < 620) return true;
    if (_winStartMs >= 0 && _now - _winStartMs < _winMs + 400) return true;
    for (final start in _revealStart.values) {
      if (_now - start < _revealMs) return true;
    }
    for (final start in _flagStart.values) {
      if (_now - start < _flagMs) return true;
    }
    return false;
  }

  void _ensureTicking() {
    if (!_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _shake.dispose();
    _frame.dispose();
    _clock.stop();
    super.dispose();
  }

  /// Sincroniza el estado de animación con el provider en cada rebuild.
  ///
  /// `build` debe ser puro: aquí solo se actualizan datos (mapas de tiempos) y
  /// se DETECTA qué animaciones/feedback disparar. Arrancar el `Ticker` /
  /// controladores y emitir háptica/SFX se difiere a un post-frame para no
  /// mutar animaciones durante el build (evita ANR / estados inconsistentes).
  void _syncAnimations(GameProvider gp) {
    var needsTick = false;
    var needsShake = false;
    var revealed = false;
    var flagged = false;

    // Tablero nuevo (nueva partida o siguiente tablero de Blitz): limpiar
    // animaciones de revelado/bandera para que el nuevo tablero anime de cero.
    if (gp.boardGeneration != _lastGeneration) {
      _lastGeneration = gp.boardGeneration;
      _revealStart.clear();
      _flagStart.clear();
      _flaggedSnapshot.clear();
    }

    if (gp.revealBatchId != _lastBatch) {
      _lastBatch = gp.revealBatchId;
      final cols = gp.board.cols;
      final base = _now;
      for (var i = 0; i < gp.lastRevealed.length; i++) {
        final c = gp.lastRevealed[i];
        final idx = c.row * cols + c.col;
        _revealStart.putIfAbsent(idx, () => base + i * _ringDelayMs);
      }
      needsTick = true;
      revealed = gp.lastRevealed.isNotEmpty;
    }

    // Detectar banderas nuevas para bounce + feedback.
    final cols = gp.board.cols;
    for (final cell in gp.board.cells) {
      if (!cell.isRevealed && cell.isFlagged) {
        final idx = cell.row * cols + cell.col;
        if (_flaggedSnapshot.add(idx)) {
          _flagStart[idx] = _now;
          needsTick = true;
          flagged = true;
        }
      }
    }
    _flaggedSnapshot.removeWhere((idx) {
      final r = idx ~/ cols, c = idx % cols;
      final cell = gp.board.inBounds(r, c) ? gp.board.cellAt(r, c) : null;
      return cell == null || cell.isRevealed || !cell.isFlagged;
    });

    if (gp.status != _lastStatus) {
      _lastStatus = gp.status;
      if (gp.status == GameStatus.lost) {
        _explodeStartMs = _now;
        needsShake = true;
        needsTick = true;
      } else if (gp.status == GameStatus.won) {
        _winStartMs = _now;
        needsTick = true;
      } else if (gp.status == GameStatus.idle) {
        // Nueva partida: limpiar animaciones.
        _revealStart.clear();
        _flagStart.clear();
        _flaggedSnapshot.clear();
        _explodeStartMs = -1;
        _winStartMs = -1;
      }
    }

    if (needsTick || needsShake || revealed || flagged) {
      final won = gp.status == GameStatus.won;
      final lost = gp.status == GameStatus.lost;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (needsShake) _shake.forward(from: 0);
        _ensureTicking();
        // Feedback (háptica + SFX). Explosión/victoria mandan sobre revelado.
        if (lost) {
          _haptics.explosion();
          _audio.play(Sfx.explosion);
        } else if (won) {
          _haptics.victory();
          _audio.play(Sfx.victory);
        } else if (revealed) {
          _haptics.reveal();
          _audio.play(Sfx.reveal);
        }
        if (flagged) {
          _haptics.flag();
          _audio.play(Sfx.flag);
        }
      });
    }
  }

  double _revealProgress(int index) {
    final start = _revealStart[index];
    if (start == null) return 1.0;
    return ((_now - start) / _revealMs).clamp(0.0, 1.0);
  }

  double _flagProgress(int index) {
    final start = _flagStart[index];
    if (start == null) return 1.0;
    return ((_now - start) / _flagMs).clamp(0.0, 1.0);
  }

  Offset _shakeOffset() {
    if (!_shake.isAnimating && _shake.value == 0) return Offset.zero;
    final t = _shake.value;
    final amp = 10.0 * (1 - t);
    return Offset(math.sin(t * math.pi * 6) * amp, 0);
  }

  double _winProgress() {
    if (_winStartMs < 0) return 0;
    return ((_now - _winStartMs) / _winMs).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final palette = context.palette;
    _syncAnimations(gp);

    final board = gp.board;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Tamaño de celda: ajusta al ancho, acotado para seguir siendo táctil.
        final fit = constraints.maxWidth / board.cols;
        final cellSize = fit.clamp(20.0, 56.0);
        final boardW = board.cols * cellSize;
        final boardH = board.rows * cellSize;

        return RepaintBoundary(
          child: InteractiveViewer(
            minScale: 0.6,
            maxScale: 4,
            boundaryMargin: const EdgeInsets.all(80),
            constrained: false,
            child: SizedBox(
              width: math.max(boardW, constraints.maxWidth),
              height: math.max(boardH, constraints.maxHeight),
              child: Center(
                child: _GestureLayer(
                  cellSize: cellSize,
                  board: board,
                  onTap: gp.onTap,
                  onLongPress: gp.onLongPress,
                  onDoubleTap: gp.onDoubleTap,
                  child: CustomPaint(
                    size: Size(boardW, boardH),
                    painter: _BoardPainter(
                      repaint: Listenable.merge([_frame, _shake]),
                      board: board,
                      palette: palette,
                      cellSize: cellSize,
                      revealProgress: _revealProgress,
                      flagProgress: _flagProgress,
                      explodedCell: gp.explodedCell,
                      explosionProgress: _explodeStartMs < 0
                          ? 0
                          : ((_now - _explodeStartMs) / 500).clamp(0.0, 1.0),
                      winProgress: _winProgress(),
                      shakeOffset: _shakeOffset(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Capa de gestos: convierte coordenadas locales en (fila, columna).
class _GestureLayer extends StatelessWidget {
  const _GestureLayer({
    required this.cellSize,
    required this.board,
    required this.onTap,
    required this.onLongPress,
    required this.onDoubleTap,
    required this.child,
  });

  final double cellSize;
  final Board board;
  final void Function(int row, int col) onTap;
  final void Function(int row, int col) onLongPress;
  final void Function(int row, int col) onDoubleTap;
  final Widget child;

  (int, int)? _cellAt(Offset local) {
    final col = (local.dx / cellSize).floor();
    final row = (local.dy / cellSize).floor();
    if (!board.inBounds(row, col)) return null;
    return (row, col);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (d) {
        final rc = _cellAt(d.localPosition);
        if (rc != null) onTap(rc.$1, rc.$2);
      },
      onLongPressStart: (d) {
        final rc = _cellAt(d.localPosition);
        if (rc != null) onLongPress(rc.$1, rc.$2);
      },
      onDoubleTapDown: (d) {
        final rc = _cellAt(d.localPosition);
        if (rc != null) onDoubleTap(rc.$1, rc.$2);
      },
      onDoubleTap: () {}, // requerido para que onDoubleTapDown reporte posición
      child: child,
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required Listenable repaint,
    required this.board,
    required this.palette,
    required this.cellSize,
    required this.revealProgress,
    required this.flagProgress,
    required this.explodedCell,
    required this.explosionProgress,
    required this.winProgress,
    required this.shakeOffset,
  }) : super(repaint: repaint);

  final Board board;
  final BoardPalette palette;
  final double cellSize;
  final double Function(int index) revealProgress;
  final double Function(int index) flagProgress;
  final Cell? explodedCell;
  final double explosionProgress;
  final double winProgress;
  final Offset shakeOffset;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(shakeOffset.dx, shakeOffset.dy);

    for (final cell in board.cells) {
      final rect = Rect.fromLTWH(
        cell.col * cellSize,
        cell.row * cellSize,
        cellSize,
        cellSize,
      );
      if (cell.isRevealed) {
        _paintRevealed(canvas, cell, rect);
      } else {
        _paintHidden(canvas, cell, rect);
      }
    }

    _paintWinWave(canvas, size);
    _paintExplosion(canvas);
    canvas.restore();
  }

  void _paintHidden(Canvas canvas, Cell cell, Rect rect) {
    final inner = rect.deflate(1);
    final rrect = RRect.fromRectAndRadius(inner, const Radius.circular(5));
    // Relieve neumórfico sutil (plan §5.1): highlight arriba, base debajo.
    canvas.drawRRect(rrect, Paint()..color = palette.surface);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(inner.left, inner.top, inner.width, inner.height * 0.5),
        const Radius.circular(5),
      ),
      Paint()..color = palette.surfaceHi.withValues(alpha: 0.35),
    );
    if (cell.isFlagged) {
      final idx = cell.row * board.cols + cell.col;
      _paintFlag(canvas, rect, flagProgress(idx));
    }
  }

  void _paintRevealed(Canvas canvas, Cell cell, Rect rect) {
    final idx = cell.row * board.cols + cell.col;
    final t = revealProgress(idx);
    final inner = rect.deflate(1);

    final isExploded = explodedCell != null &&
        cell.row == explodedCell!.row &&
        cell.col == explodedCell!.col;

    canvas.save();
    // Flip de entrada (plan §5.2): la celda "abre" desde canto con easeOut,
    // escalando en X como un giro, más un leve asentamiento en Y.
    final e = Curves.easeOutCubic.transform(t);
    final scaleX = 0.15 + 0.85 * math.cos((1 - e) * math.pi / 2);
    final scaleY = 0.85 + 0.15 * e;
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.scale(scaleX, scaleY);
    canvas.translate(-rect.center.dx, -rect.center.dy);

    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, const Radius.circular(4)),
      Paint()
        ..color = cell.hasMine && isExploded
            ? palette.danger
            : palette.surfaceLow,
    );

    if (cell.hasMine) {
      _paintMine(canvas, rect, exploded: isExploded);
    } else if (cell.adjacentMines > 0) {
      _paintNumber(canvas, cell, rect, e);
    }
    canvas.restore();
  }

  void _paintNumber(Canvas canvas, Cell cell, Rect rect, double t) {
    final tp = TextPainter(
      text: TextSpan(
        text: '${cell.shownNumber}',
        style: TextStyle(
          color: palette.forNumber(cell.shownNumber).withValues(alpha: t),
          fontSize: cellSize * 0.56,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      rect.center - Offset(tp.width / 2, tp.height / 2),
    );
  }

  void _paintMine(Canvas canvas, Rect rect, {required bool exploded}) {
    final c = rect.center;
    final r = cellSize * 0.24;
    final paint = Paint()
      ..color = exploded ? palette.onAccent : palette.danger;
    // Cuerpo + púas simples (vectorial, plan §5.1).
    canvas.drawCircle(c, r, paint);
    final spike = Paint()
      ..color = paint.color
      ..strokeWidth = cellSize * 0.06
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final o = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + o * (r * 0.6), c + o * (r * 1.5), spike);
    }
  }

  void _paintFlag(Canvas canvas, Rect rect, double t) {
    // Bounce: la bandera "cae" con overshoot (scale 0→1.15→1, plan §5.2).
    final scale = t >= 1
        ? 1.0
        : Curves.easeOutBack.transform(t).clamp(0.0, 1.15);
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.scale(scale);
    canvas.translate(-rect.center.dx, -rect.center.dy);

    final poleX = rect.left + cellSize * 0.38;
    final top = rect.top + cellSize * 0.24;
    final bottom = rect.bottom - cellSize * 0.24;
    canvas.drawLine(
      Offset(poleX, top),
      Offset(poleX, bottom),
      Paint()
        ..color = palette.textMuted
        ..strokeWidth = cellSize * 0.06
        ..strokeCap = StrokeCap.round,
    );
    final flag = Path()
      ..moveTo(poleX, top)
      ..lineTo(poleX + cellSize * 0.28, top + cellSize * 0.12)
      ..lineTo(poleX, top + cellSize * 0.24)
      ..close();
    canvas.drawPath(flag, Paint()..color = palette.secondary);
    canvas.restore();
  }

  /// Wave de victoria (plan §5.2): banda de brillo verde que recorre el tablero
  /// de izquierda a derecha sobre las celdas.
  void _paintWinWave(Canvas canvas, Size size) {
    if (winProgress <= 0 || winProgress >= 1) return;
    final bandW = size.width * 0.32;
    final x = -bandW + (size.width + bandW * 2) * winProgress;
    final rect = Rect.fromLTWH(x - bandW / 2, 0, bandW, size.height);
    final shader = LinearGradient(
      colors: [
        palette.primary.withValues(alpha: 0),
        palette.primary.withValues(alpha: 0.35),
        palette.primary.withValues(alpha: 0),
      ],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = shader);
  }

  void _paintExplosion(Canvas canvas) {
    if (explodedCell == null || explosionProgress <= 0) return;
    final center = Offset(
      (explodedCell!.col + 0.5) * cellSize,
      (explodedCell!.row + 0.5) * cellSize,
    );
    final maxR = cellSize * 4;
    final radius = maxR * Curves.easeOut.transform(explosionProgress);
    final alpha = (1 - explosionProgress).clamp(0.0, 1.0);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cellSize * 0.18
        ..color = palette.danger.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) =>
      old.palette != palette || true;
}
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/skins.dart';
import '../../../domain/models/board.dart';
import '../../../domain/models/cell.dart';
import '../../../providers/economy_provider.dart';
import '../../../providers/game_provider.dart';

/// Render 2.5D del modo Torre 3D (plan §2.6): capas apiladas con perspectiva
/// `Matrix4` (100% Flutter, sin motores externos). Solo la capa superior es
/// interactiva; las inferiores se ven debajo, semitransparentes. Gesto de dos
/// dedos para rotar la vista ±30° (cosmético). El punto indicador de "mina
/// debajo" lo aporta [Cell.minedBelow] (calculado en `TowerEngine`).
class TowerBoardWidget extends StatefulWidget {
  const TowerBoardWidget({super.key});

  @override
  State<TowerBoardWidget> createState() => _TowerBoardWidgetState();
}

class _TowerBoardWidgetState extends State<TowerBoardWidget> {
  /// Rotación cosmética de la vista (rad), limitada a ±30°.
  double _rotation = 0;
  double _rotationStart = 0;
  static const _maxRotation = 0.52; // ~30°

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final tower = gp.tower;
    if (tower == null) return const SizedBox.shrink();

    final economy = context.watch<EconomyProvider>();
    final palette = boardPaletteFor(economy.equippedBoardSkin, context.palette);
    final piece = pieceColorsFor(economy.equippedPieceSkin, palette);
    final active = tower.activeLayer;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        final cellSize = (side * 0.72) / tower.active.cols;
        final boardW = tower.active.cols * cellSize;
        final boardH = tower.active.rows * cellSize;
        final gap = cellSize * 0.95; // separación vertical entre capas
        final visibleCount = active + 1;

        return GestureDetector(
          // Dos dedos = rotar la vista (cosmético, plan §2.6). Un dedo no rota,
          // para no interferir con los toques del tablero.
          onScaleStart: (_) => _rotationStart = _rotation,
          onScaleUpdate: (d) {
            if (d.pointerCount >= 2) {
              setState(() => _rotation =
                  (_rotationStart + d.rotation).clamp(-_maxRotation, _maxRotation));
            }
          },
          child: Center(
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015) // profundidad de perspectiva
                ..rotateX(-0.5) // inclinación isométrica
                ..rotateZ(_rotation),
              child: SizedBox(
                width: boardW,
                height: boardH + gap * (visibleCount - 1),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // De la capa del fondo (0) a la activa: la activa se pinta
                    // encima (última en la lista).
                    for (var l = 0; l <= active; l++)
                      Positioned(
                        top: (active - l) * gap,
                        child: _LayerView(
                          board: tower.layers[l],
                          cellSize: cellSize,
                          palette: palette,
                          flagColor: piece.flag,
                          mineColor: piece.mine,
                          isActive: l == active,
                          depth: active - l,
                          explodedCell: l == active ? gp.explodedCell : null,
                          onTap: gp.onTap,
                          onLongPress: gp.onLongPress,
                          onDoubleTap: gp.onDoubleTap,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Una capa de la torre. La activa recibe gestos; las inferiores se atenúan.
class _LayerView extends StatelessWidget {
  const _LayerView({
    required this.board,
    required this.cellSize,
    required this.palette,
    required this.flagColor,
    required this.mineColor,
    required this.isActive,
    required this.depth,
    required this.explodedCell,
    required this.onTap,
    required this.onLongPress,
    required this.onDoubleTap,
  });

  final Board board;
  final double cellSize;
  final BoardPalette palette;
  final Color flagColor;
  final Color mineColor;
  final bool isActive;
  final int depth;
  final Cell? explodedCell;
  final void Function(int row, int col) onTap;
  final void Function(int row, int col) onLongPress;
  final void Function(int row, int col) onDoubleTap;

  (int, int)? _cellAt(Offset local) {
    final col = (local.dx / cellSize).floor();
    final row = (local.dy / cellSize).floor();
    if (!board.inBounds(row, col)) return null;
    return (row, col);
  }

  @override
  Widget build(BuildContext context) {
    final painter = CustomPaint(
      size: Size(board.cols * cellSize, board.rows * cellSize),
      painter: _TowerLayerPainter(
        board: board,
        palette: palette,
        flagColor: flagColor,
        mineColor: mineColor,
        explodedCell: explodedCell,
        dim: isActive ? 0.0 : (0.35 + depth * 0.12).clamp(0.0, 0.72),
      ),
    );

    if (!isActive) {
      // Capas inferiores: no interactivas y atenuadas.
      return Opacity(
        opacity: (1 - depth * 0.16).clamp(0.35, 1.0),
        child: IgnorePointer(child: painter),
      );
    }

    // Capa activa: interactiva. Entra con un leve "pop" al cambiar de capa.
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
      onDoubleTap: () {},
      child: painter,
    ).animate().fadeIn(duration: 220.ms).scaleXY(
          begin: 0.94,
          end: 1,
          duration: 260.ms,
          curve: Curves.easeOutBack,
        );
  }
}

class _TowerLayerPainter extends CustomPainter {
  _TowerLayerPainter({
    required this.board,
    required this.palette,
    required this.flagColor,
    required this.mineColor,
    required this.explodedCell,
    required this.dim,
  });

  final Board board;
  final BoardPalette palette;
  final Color flagColor;
  final Color mineColor;
  final Cell? explodedCell;

  /// Oscurecimiento (0 = sin, 1 = negro) para dar profundidad a capas inferiores.
  final double dim;

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / board.cols;
    for (final cell in board.cells) {
      final rect = Rect.fromLTWH(
        cell.col * cellSize,
        cell.row * cellSize,
        cellSize,
        cellSize,
      );
      if (cell.isRevealed) {
        _paintRevealed(canvas, cell, rect, cellSize);
      } else {
        _paintHidden(canvas, cell, rect, cellSize);
      }
    }
    if (dim > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = palette.bg.withValues(alpha: dim),
      );
    }
  }

  void _paintHidden(Canvas canvas, Cell cell, Rect rect, double cellSize) {
    final inner = rect.deflate(1);
    final rrect = RRect.fromRectAndRadius(inner, const Radius.circular(5));
    canvas.drawRRect(rrect, Paint()..color = palette.surface);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(inner.left, inner.top, inner.width, inner.height * 0.5),
        const Radius.circular(5),
      ),
      Paint()..color = palette.surfaceHi.withValues(alpha: 0.35),
    );
    if (cell.isFlagged) _paintFlag(canvas, rect, cellSize);
  }

  void _paintRevealed(Canvas canvas, Cell cell, Rect rect, double cellSize) {
    final inner = rect.deflate(1);
    final isExploded = explodedCell != null &&
        cell.row == explodedCell!.row &&
        cell.col == explodedCell!.col;
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, const Radius.circular(4)),
      Paint()
        ..color = cell.hasMine && isExploded ? palette.danger : palette.surfaceLow,
    );
    if (cell.hasMine) {
      _paintMine(canvas, rect, cellSize, exploded: isExploded);
    } else if (cell.adjacentMines > 0) {
      _paintNumber(canvas, cell, rect, cellSize);
    }
    // Punto indicador: la mina contada está en la capa de abajo (§2.6).
    if (cell.minedBelow) {
      canvas.drawCircle(
        Offset(inner.left + cellSize * 0.18, inner.top + cellSize * 0.18),
        cellSize * 0.08,
        Paint()..color = palette.danger,
      );
    }
  }

  void _paintNumber(Canvas canvas, Cell cell, Rect rect, double cellSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: '${cell.shownNumber}',
        style: TextStyle(
          color: palette.forNumber(cell.shownNumber),
          fontSize: cellSize * 0.56,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, rect.center - Offset(tp.width / 2, tp.height / 2));
  }

  void _paintMine(Canvas canvas, Rect rect, double cellSize,
      {required bool exploded}) {
    final c = rect.center;
    final r = cellSize * 0.24;
    final paint = Paint()..color = exploded ? palette.onAccent : mineColor;
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

  void _paintFlag(Canvas canvas, Rect rect, double cellSize) {
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
    canvas.drawPath(flag, Paint()..color = flagColor);
  }

  @override
  bool shouldRepaint(covariant _TowerLayerPainter old) => true;
}
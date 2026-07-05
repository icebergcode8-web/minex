import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/difficulty.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/records_repository.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/app_card.dart';

/// Estadísticas por dificultad del modo clásico (plan §8, StatsScreen).
/// Incluye una gráfica simple de winrate hecha con `CustomPaint`.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  static const _order = [
    Difficulty.easy,
    Difficulty.medium,
    Difficulty.hard,
    Difficulty.expert,
  ];

  @override
  Widget build(BuildContext context) {
    final records = context.read<RecordsRepository>();
    final palette = context.palette;
    final l = AppLocalizations.of(context)!;

    final rows = [
      for (final d in _order)
        (
          difficulty: d,
          played: records.played(d),
          wins: records.wins(d),
          best: records.bestTimeMs(d),
        ),
    ];
    final totalPlayed = rows.fold<int>(0, (a, r) => a + r.played);

    return Scaffold(
      appBar: AppBar(title: Text(l.statsTitle)),
      body: AppBackground(
        child: totalPlayed == 0
            ? Center(
                child: Text(
                  l.statsEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.textMuted, fontSize: 16),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.statsWinrate,
                          style: TextStyle(
                            color: palette.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 150,
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _WinrateChart(
                              values: [
                                for (final r in rows)
                                  r.played == 0 ? 0.0 : r.wins / r.played,
                              ],
                              labels: [
                                l.difficultyEasy[0],
                                l.difficultyMedium[0],
                                l.difficultyHard[0],
                                l.difficultyExpert[0],
                              ],
                              palette: palette,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final r in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _StatRow(
                        label: switch (r.difficulty) {
                          Difficulty.easy => l.difficultyEasy,
                          Difficulty.medium => l.difficultyMedium,
                          Difficulty.hard => l.difficultyHard,
                          Difficulty.expert => l.difficultyExpert,
                          Difficulty.custom => l.difficultyExpert,
                        },
                        played: r.played,
                        wins: r.wins,
                        best: r.best,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.played,
    required this.wins,
    required this.best,
  });

  final String label;
  final int played;
  final int wins;
  final int? best;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l = AppLocalizations.of(context)!;
    final winrate = played == 0 ? 0 : (wins / played * 100).round();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Metric(label: l.statsPlayed, value: '$played'),
              _Metric(label: l.statsWins, value: '$wins'),
              _Metric(
                  label: l.statsWinrate, value: l.winratePercent(winrate)),
              _Metric(
                label: l.statsBestTime,
                value: best != null ? formatRecord(best!) : l.noRecord,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTheme.mono(
              fontSize: 15,
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: palette.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _WinrateChart extends CustomPainter {
  _WinrateChart({
    required this.values,
    required this.labels,
    required this.palette,
  });

  final List<double> values; // 0..1
  final List<String> labels;
  final BoardPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    const labelH = 22.0;
    final chartH = size.height - labelH;
    final n = values.length;
    final slot = size.width / n;
    final barW = slot * 0.5;

    // Línea base.
    final baseY = chartH;
    canvas.drawLine(
      Offset(0, baseY),
      Offset(size.width, baseY),
      Paint()..color = palette.border,
    );

    for (var i = 0; i < n; i++) {
      final cx = slot * i + slot / 2;
      final h = (chartH - 6) * values[i].clamp(0.0, 1.0);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - barW / 2, baseY - h, barW, h),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, Paint()..color = palette.primary);

      // Etiqueta.
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(color: palette.textMuted, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, baseY + 5));
    }
  }

  @override
  bool shouldRepaint(covariant _WinrateChart old) =>
      old.values != values || old.palette != palette;
}
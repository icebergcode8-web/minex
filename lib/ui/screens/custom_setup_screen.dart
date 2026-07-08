import 'package:flutter/material.dart';

import '../../core/constants/difficulty.dart';
import '../../core/constants/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/primary_button.dart';

/// Configuración de tablero personalizado (plan §2.1): 5×5 a 30×40, minas
/// libres hasta el 30% de densidad. Valida en vivo y respeta los límites de
/// [kCustomMinSide]/[kCustomMaxRows]/[kCustomMaxCols]/[kCustomMaxDensity].
class CustomSetupScreen extends StatefulWidget {
  const CustomSetupScreen({super.key});

  @override
  State<CustomSetupScreen> createState() => _CustomSetupScreenState();
}

class _CustomSetupScreenState extends State<CustomSetupScreen> {
  int _rows = 12;
  int _cols = 10;
  int _mines = 20;

  int get _maxMines =>
      (_rows * _cols * kCustomMaxDensity).floor().clamp(1, _rows * _cols);

  int get _densityPercent => (_mines / (_rows * _cols) * 100).round();

  void _setRows(int v) {
    setState(() {
      _rows = v;
      _mines = _mines.clamp(1, _maxMines);
    });
  }

  void _setCols(int v) {
    setState(() {
      _cols = v;
      _mines = _mines.clamp(1, _maxMines);
    });
  }

  void _start() {
    Navigator.of(context).pushReplacementNamed(
      Routes.game,
      arguments: GameArgs(
        config: classicCustomConfig(rows: _rows, cols: _cols, mines: _mines),
        difficulty: Difficulty.custom,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.customTitle)),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              AppCard(
                child: Column(
                  children: [
                    _SliderRow(
                      label: l.customRows,
                      value: _rows,
                      min: kCustomMinSide,
                      max: kCustomMaxRows,
                      onChanged: _setRows,
                    ),
                    const SizedBox(height: 8),
                    _SliderRow(
                      label: l.customCols,
                      value: _cols,
                      min: kCustomMinSide,
                      max: kCustomMaxCols,
                      onChanged: _setCols,
                    ),
                    const SizedBox(height: 8),
                    _SliderRow(
                      label: l.customMines,
                      value: _mines,
                      min: 1,
                      max: _maxMines,
                      trailing: l.customMinesMax(_maxMines),
                      onChanged: (v) => setState(() => _mines = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: palette.border),
                  ),
                  child: Text(
                    '$_rows×$_cols  ·  ${l.customDensity(_densityPercent)}',
                    style: AppTheme.mono(
                      fontSize: 14,
                      color: palette.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: PrimaryButton(
                  label: l.customStart,
                  icon: Icons.play_arrow_rounded,
                  onPressed: _start,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.trailing,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                )),
            const Spacer(),
            if (trailing != null) ...[
              Text(trailing!,
                  style: TextStyle(color: palette.textMuted, fontSize: 12)),
              const SizedBox(width: 8),
            ],
            Text(
              '$value',
              style: AppTheme.mono(
                fontSize: 16,
                color: palette.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: (max - min) > 0 ? (max - min) : null,
          activeColor: palette.primary,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}
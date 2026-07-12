import 'package:flutter_test/flutter_test.dart';
import 'package:minex/core/constants/difficulty.dart';
import 'package:minex/domain/engine/daily_engine.dart';
import 'package:minex/domain/models/game_mode.dart';

void main() {
  const engine = DailyEngine();

  test('seed = yyyyMMdd de la fecha', () {
    expect(engine.seedFor(DateTime(2026, 7, 12)), 20260712);
    expect(engine.seedFor(DateTime(2024, 1, 1)), 20240101);
  });

  test('rotación semanal de modos (plan §2.7)', () {
    // 2024-01-01 es lunes.
    final monday = DateTime(2024, 1, 1);
    expect(engine.modeFor(monday), GameMode.classic);
    expect(engine.modeFor(monday.add(const Duration(days: 1))), GameMode.fog);
    expect(engine.modeFor(monday.add(const Duration(days: 2))), GameMode.blitz);
    expect(engine.modeFor(monday.add(const Duration(days: 3))), GameMode.liar);
    expect(
        engine.modeFor(monday.add(const Duration(days: 4))), GameMode.classic);
    expect(engine.modeFor(monday.add(const Duration(days: 5))), GameMode.waves);
    expect(engine.modeFor(monday.add(const Duration(days: 6))), GameMode.tower);
  });

  test('el viernes es clásico difícil', () {
    final friday = DateTime(2024, 1, 5);
    final spec = engine.specFor(friday);
    expect(spec.mode, GameMode.classic);
    expect(spec.difficulty, Difficulty.hard);
    expect(spec.config.seed, 20240105);
  });

  test('consecutividad y mismo día', () {
    final a = DateTime(2024, 1, 1, 23, 59);
    final b = DateTime(2024, 1, 2, 0, 1);
    final c = DateTime(2024, 1, 3);
    expect(engine.isNextDay(a, b), isTrue);
    expect(engine.isNextDay(a, c), isFalse);
    expect(engine.isSameDay(a, DateTime(2024, 1, 1, 8)), isTrue);
  });

  test('specFor es determinista para la misma fecha', () {
    final d = DateTime(2025, 3, 10);
    final s1 = engine.specFor(d);
    final s2 = engine.specFor(d);
    expect(s1.config.seed, s2.config.seed);
    expect(s1.mode, s2.mode);
  });

  test('domingo (torre) hace fallback a clásico experto hasta la Fase 6', () {
    final sunday = DateTime(2024, 1, 7);
    final spec = engine.specFor(sunday);
    expect(spec.mode, GameMode.tower);
    expect(spec.config.mode, GameMode.classic);
    expect(spec.difficulty, Difficulty.expert);
  });
}
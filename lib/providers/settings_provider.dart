import 'package:flutter/material.dart';

import '../core/audio/audio_service.dart';
import '../core/haptics/haptics_service.dart';
import '../data/repositories/settings_repository.dart';

/// Estado global de ajustes (plan §8.5). Lee/escribe en [SettingsRepository] y
/// mantiene sincronizados los servicios de audio/háptica con los switches del
/// jugador. Se provee de forma global (a diferencia de `GameProvider`, scoped).
///
// Nombres de parámetro públicos con campos privados a propósito (igual que
// GameProvider): la lista de inicialización es deliberada.
// ignore_for_file: prefer_initializing_formals
class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    required SettingsRepository repo,
    required AudioService audio,
    required HapticsService haptics,
  })  : _repo = repo,
        _audio = audio,
        _haptics = haptics {
    _syncServices();
  }

  final SettingsRepository _repo;
  final AudioService _audio;
  final HapticsService _haptics;

  // ── Tema ────────────────────────────────────────────────────────────
  ThemeMode get themeMode => _parseThemeMode(_repo.themeMode);

  set themeMode(ThemeMode mode) {
    _repo.themeMode = mode.name; // system | light | dark
    notifyListeners();
  }

  static ThemeMode _parseThemeMode(String v) => switch (v) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  // ── Idioma ──────────────────────────────────────────────────────────
  /// 'es' (default) o 'en'.
  String get localeCode => _repo.localeCode;
  Locale get locale => Locale(_repo.localeCode);

  set localeCode(String code) {
    _repo.localeCode = code;
    notifyListeners();
  }

  // ── Audio / háptica ─────────────────────────────────────────────────
  bool get soundEnabled => _repo.soundEnabled;
  set soundEnabled(bool v) {
    _repo.soundEnabled = v;
    _audio.sfxEnabled = v;
    notifyListeners();
  }

  bool get musicEnabled => _repo.musicEnabled;
  set musicEnabled(bool v) {
    _repo.musicEnabled = v;
    _audio.musicEnabled = v;
    notifyListeners();
  }

  bool get vibrationEnabled => _repo.vibrationEnabled;
  set vibrationEnabled(bool v) {
    _repo.vibrationEnabled = v;
    _haptics.enabled = v;
    notifyListeners();
  }

  // ── Controles ───────────────────────────────────────────────────────
  bool get invertControls => _repo.invertControls;
  set invertControls(bool v) {
    _repo.invertControls = v;
    notifyListeners();
  }

  void _syncServices() {
    _audio.sfxEnabled = _repo.soundEnabled;
    _audio.musicEnabled = _repo.musicEnabled;
    _haptics.enabled = _repo.vibrationEnabled;
  }
}
import '../local/hive_service.dart';

/// Ajustes del jugador (plan §8.5). Persistidos en `settingsBox`.
///
/// Repositorio = única capa que toca Hive para estos datos (plan §6.3).
class SettingsRepository {
  SettingsRepository(this._hive);

  final HiveService _hive;

  static const _kSound = 'sound';
  static const _kMusic = 'music';
  static const _kVibration = 'vibration';
  static const _kDarkTheme = 'darkTheme';
  static const _kLocale = 'locale';
  static const _kInvertControls = 'invertControls';

  bool get soundEnabled => _hive.settings.get(_kSound, defaultValue: true);
  set soundEnabled(bool v) => _hive.settings.put(_kSound, v);

  bool get musicEnabled => _hive.settings.get(_kMusic, defaultValue: false);
  set musicEnabled(bool v) => _hive.settings.put(_kMusic, v);

  bool get vibrationEnabled =>
      _hive.settings.get(_kVibration, defaultValue: true);
  set vibrationEnabled(bool v) => _hive.settings.put(_kVibration, v);

  bool get darkTheme => _hive.settings.get(_kDarkTheme, defaultValue: true);
  set darkTheme(bool v) => _hive.settings.put(_kDarkTheme, v);

  /// Código de idioma: 'es' (default) o 'en'.
  String get localeCode => _hive.settings.get(_kLocale, defaultValue: 'es');
  set localeCode(String v) => _hive.settings.put(_kLocale, v);

  /// Si `true`, tap = bandera y long-press = revelar (plan §4.3).
  bool get invertControls =>
      _hive.settings.get(_kInvertControls, defaultValue: false);
  set invertControls(bool v) => _hive.settings.put(_kInvertControls, v);
}

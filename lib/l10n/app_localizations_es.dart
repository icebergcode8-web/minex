// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Minex';

  @override
  String get appTagline => 'Buscaminas retro moderno';

  @override
  String get play => 'JUGAR';

  @override
  String get modesTitle => 'Elige un modo';

  @override
  String get modeClassic => 'Clásico';

  @override
  String get modeClassicDesc => 'El buscaminas de siempre, pulido.';

  @override
  String get modeFog => 'Niebla';

  @override
  String get modeFogDesc => 'Solo ves lo que tienes cerca.';

  @override
  String get modeBlitz => 'Contrarreloj';

  @override
  String get modeBlitzDesc => 'Resuelve contra el cronómetro.';

  @override
  String get modeLiar => 'Mentiroso';

  @override
  String get modeLiarDesc => 'Algunos números mienten.';

  @override
  String get modeWaves => 'Oleadas';

  @override
  String get modeWavesDesc => 'Sobrevive oleada tras oleada.';

  @override
  String get modeTower => 'Torre 3D';

  @override
  String get modeTowerDesc => 'Buscaminas por capas.';

  @override
  String get modeDaily => 'Reto Diario';

  @override
  String get modeDailyDesc => 'Un tablero nuevo cada día.';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get classicMode => 'Modo Clásico';

  @override
  String get difficultyEasy => 'Fácil';

  @override
  String get difficultyMedium => 'Medio';

  @override
  String get difficultyHard => 'Difícil';

  @override
  String get difficultyExpert => 'Experto';

  @override
  String get difficultyCustom => 'Personalizado';

  @override
  String get customTitle => 'Tablero personalizado';

  @override
  String get customRows => 'Filas';

  @override
  String get customCols => 'Columnas';

  @override
  String get customMines => 'Minas';

  @override
  String get customStart => 'Empezar';

  @override
  String customDensity(int percent) {
    return 'Densidad $percent%';
  }

  @override
  String customMinesMax(int max) {
    return 'máx $max';
  }

  @override
  String boardSummary(int rows, int cols, int mines) {
    return '$rows×$cols · $mines minas';
  }

  @override
  String get bestLabel => 'Mejor';

  @override
  String get noRecord => '— —';

  @override
  String get reveal => 'Revelar';

  @override
  String get flag => 'Bandera';

  @override
  String get blitzScoreLabel => 'Puntos';

  @override
  String get blitzBoardsLabel => 'Tableros';

  @override
  String get blitzTimeUp => '¡Se acabó el tiempo!';

  @override
  String blitzBest(int score) {
    return 'Mejor: $score';
  }

  @override
  String get comboLabel => 'COMBO';

  @override
  String get freezer => 'Congelar';

  @override
  String get wavesWaveLabel => 'Oleada';

  @override
  String get wavesLivesLabel => 'Vidas';

  @override
  String get wavesScoreLabel => 'Puntos';

  @override
  String get wavesChooseUpgrade => 'Elige una mejora';

  @override
  String get wavesGameOver => 'Game Over';

  @override
  String wavesReached(int wave) {
    return 'Llegaste a la oleada $wave';
  }

  @override
  String get upgradeExtraLife => '+1 Vida';

  @override
  String get upgradeExtraLifeDesc => 'Recupera una vida (máx 5).';

  @override
  String get upgradeShield => 'Escudo';

  @override
  String get upgradeShieldDesc => 'Absorbe el próximo error sin costar vida.';

  @override
  String get upgradeRadar => 'Radar';

  @override
  String get upgradeRadarDesc => 'Marca 1 mina al inicio de cada oleada.';

  @override
  String get upgradeVision => 'Visión';

  @override
  String get upgradeVisionDesc =>
      'Revela una zona segura al empezar la próxima oleada.';

  @override
  String get upgradeItemCharge => 'Carga extra';

  @override
  String get upgradeItemChargeDesc => '+1 carga de escudo.';

  @override
  String get continueWaves => 'Continuar Oleadas';

  @override
  String get modChainedMines => 'Minas encadenadas';

  @override
  String get modPartialFog => 'Niebla parcial';

  @override
  String get modLiarNumbers => 'Números mentirosos';

  @override
  String get modDelayedMines => 'Minas con retardo';

  @override
  String get waveNewMines => '¡Minas nuevas!';

  @override
  String get pauseTitle => 'Pausa';

  @override
  String get resume => 'Continuar';

  @override
  String get restart => 'Reiniciar';

  @override
  String get exit => 'Salir';

  @override
  String get menu => 'Menú';

  @override
  String get victory => '¡Victoria!';

  @override
  String get defeat => 'Boom 💥';

  @override
  String get timeLabel => 'Tiempo';

  @override
  String get newRecord => '¡NUEVO RÉCORD!';

  @override
  String get youHitMine => 'Tocaste una mina';

  @override
  String get playAgain => 'Jugar de nuevo';

  @override
  String get retry => 'Reintentar';

  @override
  String get statsTitle => 'Estadísticas';

  @override
  String get statsPlayed => 'Partidas';

  @override
  String get statsWins => 'Victorias';

  @override
  String get statsWinrate => 'Winrate';

  @override
  String get statsBestTime => 'Mejor tiempo';

  @override
  String get statsEmpty => 'Aún no hay partidas.\n¡Juega una y vuelve!';

  @override
  String winratePercent(int value) {
    return '$value%';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsSound => 'Efectos de sonido';

  @override
  String get settingsMusic => 'Música';

  @override
  String get settingsGameplay => 'Juego';

  @override
  String get settingsVibration => 'Vibración';

  @override
  String get settingsInvertControls => 'Invertir toque / bandera';

  @override
  String get settingsInvertControlsDesc =>
      'Toca para poner bandera; mantén para revelar.';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsVersion => 'Versión';

  @override
  String get navStats => 'Estadísticas';

  @override
  String get navSettings => 'Ajustes';
}

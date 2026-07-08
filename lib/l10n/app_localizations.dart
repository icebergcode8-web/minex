import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// Nombre de la aplicación
  ///
  /// In es, this message translates to:
  /// **'Minex'**
  String get appTitle;

  /// Eslogan bajo el logo
  ///
  /// In es, this message translates to:
  /// **'Buscaminas retro moderno'**
  String get appTagline;

  /// Botón principal para empezar a jugar
  ///
  /// In es, this message translates to:
  /// **'JUGAR'**
  String get play;

  /// No description provided for @modesTitle.
  ///
  /// In es, this message translates to:
  /// **'Elige un modo'**
  String get modesTitle;

  /// No description provided for @modeClassic.
  ///
  /// In es, this message translates to:
  /// **'Clásico'**
  String get modeClassic;

  /// No description provided for @modeClassicDesc.
  ///
  /// In es, this message translates to:
  /// **'El buscaminas de siempre, pulido.'**
  String get modeClassicDesc;

  /// No description provided for @modeFog.
  ///
  /// In es, this message translates to:
  /// **'Niebla'**
  String get modeFog;

  /// No description provided for @modeFogDesc.
  ///
  /// In es, this message translates to:
  /// **'Solo ves lo que tienes cerca.'**
  String get modeFogDesc;

  /// No description provided for @modeBlitz.
  ///
  /// In es, this message translates to:
  /// **'Contrarreloj'**
  String get modeBlitz;

  /// No description provided for @modeBlitzDesc.
  ///
  /// In es, this message translates to:
  /// **'Resuelve contra el cronómetro.'**
  String get modeBlitzDesc;

  /// No description provided for @modeLiar.
  ///
  /// In es, this message translates to:
  /// **'Mentiroso'**
  String get modeLiar;

  /// No description provided for @modeLiarDesc.
  ///
  /// In es, this message translates to:
  /// **'Algunos números mienten.'**
  String get modeLiarDesc;

  /// No description provided for @modeWaves.
  ///
  /// In es, this message translates to:
  /// **'Oleadas'**
  String get modeWaves;

  /// No description provided for @modeWavesDesc.
  ///
  /// In es, this message translates to:
  /// **'Sobrevive oleada tras oleada.'**
  String get modeWavesDesc;

  /// No description provided for @modeTower.
  ///
  /// In es, this message translates to:
  /// **'Torre 3D'**
  String get modeTower;

  /// No description provided for @modeTowerDesc.
  ///
  /// In es, this message translates to:
  /// **'Buscaminas por capas.'**
  String get modeTowerDesc;

  /// No description provided for @modeDaily.
  ///
  /// In es, this message translates to:
  /// **'Reto Diario'**
  String get modeDaily;

  /// No description provided for @modeDailyDesc.
  ///
  /// In es, this message translates to:
  /// **'Un tablero nuevo cada día.'**
  String get modeDailyDesc;

  /// Etiqueta en modos aún no disponibles
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get comingSoon;

  /// No description provided for @classicMode.
  ///
  /// In es, this message translates to:
  /// **'Modo Clásico'**
  String get classicMode;

  /// No description provided for @difficultyEasy.
  ///
  /// In es, this message translates to:
  /// **'Fácil'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In es, this message translates to:
  /// **'Medio'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In es, this message translates to:
  /// **'Difícil'**
  String get difficultyHard;

  /// No description provided for @difficultyExpert.
  ///
  /// In es, this message translates to:
  /// **'Experto'**
  String get difficultyExpert;

  /// No description provided for @difficultyCustom.
  ///
  /// In es, this message translates to:
  /// **'Personalizado'**
  String get difficultyCustom;

  /// No description provided for @customTitle.
  ///
  /// In es, this message translates to:
  /// **'Tablero personalizado'**
  String get customTitle;

  /// No description provided for @customRows.
  ///
  /// In es, this message translates to:
  /// **'Filas'**
  String get customRows;

  /// No description provided for @customCols.
  ///
  /// In es, this message translates to:
  /// **'Columnas'**
  String get customCols;

  /// No description provided for @customMines.
  ///
  /// In es, this message translates to:
  /// **'Minas'**
  String get customMines;

  /// No description provided for @customStart.
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get customStart;

  /// No description provided for @customDensity.
  ///
  /// In es, this message translates to:
  /// **'Densidad {percent}%'**
  String customDensity(int percent);

  /// No description provided for @customMinesMax.
  ///
  /// In es, this message translates to:
  /// **'máx {max}'**
  String customMinesMax(int max);

  /// Resumen de tamaño de tablero y minas
  ///
  /// In es, this message translates to:
  /// **'{rows}×{cols} · {mines} minas'**
  String boardSummary(int rows, int cols, int mines);

  /// No description provided for @bestLabel.
  ///
  /// In es, this message translates to:
  /// **'Mejor'**
  String get bestLabel;

  /// No description provided for @noRecord.
  ///
  /// In es, this message translates to:
  /// **'— —'**
  String get noRecord;

  /// No description provided for @reveal.
  ///
  /// In es, this message translates to:
  /// **'Revelar'**
  String get reveal;

  /// No description provided for @flag.
  ///
  /// In es, this message translates to:
  /// **'Bandera'**
  String get flag;

  /// No description provided for @blitzScoreLabel.
  ///
  /// In es, this message translates to:
  /// **'Puntos'**
  String get blitzScoreLabel;

  /// No description provided for @blitzBoardsLabel.
  ///
  /// In es, this message translates to:
  /// **'Tableros'**
  String get blitzBoardsLabel;

  /// No description provided for @blitzTimeUp.
  ///
  /// In es, this message translates to:
  /// **'¡Se acabó el tiempo!'**
  String get blitzTimeUp;

  /// No description provided for @blitzBest.
  ///
  /// In es, this message translates to:
  /// **'Mejor: {score}'**
  String blitzBest(int score);

  /// No description provided for @comboLabel.
  ///
  /// In es, this message translates to:
  /// **'COMBO'**
  String get comboLabel;

  /// No description provided for @freezer.
  ///
  /// In es, this message translates to:
  /// **'Congelar'**
  String get freezer;

  /// No description provided for @pauseTitle.
  ///
  /// In es, this message translates to:
  /// **'Pausa'**
  String get pauseTitle;

  /// No description provided for @resume.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get resume;

  /// No description provided for @restart.
  ///
  /// In es, this message translates to:
  /// **'Reiniciar'**
  String get restart;

  /// No description provided for @exit.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get exit;

  /// No description provided for @menu.
  ///
  /// In es, this message translates to:
  /// **'Menú'**
  String get menu;

  /// No description provided for @victory.
  ///
  /// In es, this message translates to:
  /// **'¡Victoria!'**
  String get victory;

  /// No description provided for @defeat.
  ///
  /// In es, this message translates to:
  /// **'Boom 💥'**
  String get defeat;

  /// No description provided for @timeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tiempo'**
  String get timeLabel;

  /// No description provided for @newRecord.
  ///
  /// In es, this message translates to:
  /// **'¡NUEVO RÉCORD!'**
  String get newRecord;

  /// No description provided for @youHitMine.
  ///
  /// In es, this message translates to:
  /// **'Tocaste una mina'**
  String get youHitMine;

  /// No description provided for @playAgain.
  ///
  /// In es, this message translates to:
  /// **'Jugar de nuevo'**
  String get playAgain;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @statsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get statsTitle;

  /// No description provided for @statsPlayed.
  ///
  /// In es, this message translates to:
  /// **'Partidas'**
  String get statsPlayed;

  /// No description provided for @statsWins.
  ///
  /// In es, this message translates to:
  /// **'Victorias'**
  String get statsWins;

  /// No description provided for @statsWinrate.
  ///
  /// In es, this message translates to:
  /// **'Winrate'**
  String get statsWinrate;

  /// No description provided for @statsBestTime.
  ///
  /// In es, this message translates to:
  /// **'Mejor tiempo'**
  String get statsBestTime;

  /// No description provided for @statsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay partidas.\n¡Juega una y vuelve!'**
  String get statsEmpty;

  /// No description provided for @winratePercent.
  ///
  /// In es, this message translates to:
  /// **'{value}%'**
  String winratePercent(int value);

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @settingsAudio.
  ///
  /// In es, this message translates to:
  /// **'Audio'**
  String get settingsAudio;

  /// No description provided for @settingsSound.
  ///
  /// In es, this message translates to:
  /// **'Efectos de sonido'**
  String get settingsSound;

  /// No description provided for @settingsMusic.
  ///
  /// In es, this message translates to:
  /// **'Música'**
  String get settingsMusic;

  /// No description provided for @settingsGameplay.
  ///
  /// In es, this message translates to:
  /// **'Juego'**
  String get settingsGameplay;

  /// No description provided for @settingsVibration.
  ///
  /// In es, this message translates to:
  /// **'Vibración'**
  String get settingsVibration;

  /// No description provided for @settingsInvertControls.
  ///
  /// In es, this message translates to:
  /// **'Invertir toque / bandera'**
  String get settingsInvertControls;

  /// No description provided for @settingsInvertControlsDesc.
  ///
  /// In es, this message translates to:
  /// **'Toca para poner bandera; mantén para revelar.'**
  String get settingsInvertControlsDesc;

  /// No description provided for @settingsAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settingsLanguage;

  /// No description provided for @settingsAbout.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión'**
  String get settingsVersion;

  /// No description provided for @navStats.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get navStats;

  /// No description provided for @navSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get navSettings;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

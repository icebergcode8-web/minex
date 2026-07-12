// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Minex';

  @override
  String get appTagline => 'Retro-modern minesweeper';

  @override
  String get play => 'PLAY';

  @override
  String get modesTitle => 'Choose a mode';

  @override
  String get modeClassic => 'Classic';

  @override
  String get modeClassicDesc => 'The minesweeper you know, polished.';

  @override
  String get modeFog => 'Fog';

  @override
  String get modeFogDesc => 'You only see what\'s near you.';

  @override
  String get modeBlitz => 'Blitz';

  @override
  String get modeBlitzDesc => 'Race against the clock.';

  @override
  String get modeLiar => 'Liar';

  @override
  String get modeLiarDesc => 'Some numbers lie.';

  @override
  String get modeWaves => 'Waves';

  @override
  String get modeWavesDesc => 'Survive wave after wave.';

  @override
  String get modeTower => '3D Tower';

  @override
  String get modeTowerDesc => 'Layered minesweeper.';

  @override
  String get modeDaily => 'Daily Challenge';

  @override
  String get modeDailyDesc => 'A fresh board every day.';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get classicMode => 'Classic Mode';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyExpert => 'Expert';

  @override
  String get difficultyCustom => 'Custom';

  @override
  String get customTitle => 'Custom board';

  @override
  String get customRows => 'Rows';

  @override
  String get customCols => 'Columns';

  @override
  String get customMines => 'Mines';

  @override
  String get customStart => 'Start';

  @override
  String customDensity(int percent) {
    return 'Density $percent%';
  }

  @override
  String customMinesMax(int max) {
    return 'max $max';
  }

  @override
  String boardSummary(int rows, int cols, int mines) {
    return '$rows×$cols · $mines mines';
  }

  @override
  String get bestLabel => 'Best';

  @override
  String get noRecord => '— —';

  @override
  String get reveal => 'Reveal';

  @override
  String get flag => 'Flag';

  @override
  String get blitzScoreLabel => 'Score';

  @override
  String get blitzBoardsLabel => 'Boards';

  @override
  String get blitzTimeUp => 'Time\'s up!';

  @override
  String blitzBest(int score) {
    return 'Best: $score';
  }

  @override
  String get comboLabel => 'COMBO';

  @override
  String get freezer => 'Freeze';

  @override
  String get wavesWaveLabel => 'Wave';

  @override
  String get wavesLivesLabel => 'Lives';

  @override
  String get wavesScoreLabel => 'Score';

  @override
  String get wavesChooseUpgrade => 'Choose an upgrade';

  @override
  String get wavesGameOver => 'Game Over';

  @override
  String wavesReached(int wave) {
    return 'You reached wave $wave';
  }

  @override
  String get upgradeExtraLife => '+1 Life';

  @override
  String get upgradeExtraLifeDesc => 'Regain a life (max 5).';

  @override
  String get upgradeShield => 'Shield';

  @override
  String get upgradeShieldDesc =>
      'Absorbs the next mistake without losing a life.';

  @override
  String get upgradeRadar => 'Radar';

  @override
  String get upgradeRadarDesc => 'Flags 1 mine at the start of each wave.';

  @override
  String get upgradeVision => 'Vision';

  @override
  String get upgradeVisionDesc =>
      'Reveals a safe zone at the start of the next wave.';

  @override
  String get upgradeItemCharge => 'Extra charge';

  @override
  String get upgradeItemChargeDesc => '+1 shield charge.';

  @override
  String get continueWaves => 'Continue Waves';

  @override
  String get modChainedMines => 'Chained mines';

  @override
  String get modPartialFog => 'Partial fog';

  @override
  String get modLiarNumbers => 'Lying numbers';

  @override
  String get modDelayedMines => 'Delayed mines';

  @override
  String get waveNewMines => 'New mines!';

  @override
  String get pauseTitle => 'Paused';

  @override
  String get resume => 'Resume';

  @override
  String get restart => 'Restart';

  @override
  String get exit => 'Exit';

  @override
  String get menu => 'Menu';

  @override
  String get victory => 'Victory!';

  @override
  String get defeat => 'Boom 💥';

  @override
  String get timeLabel => 'Time';

  @override
  String get newRecord => 'NEW RECORD!';

  @override
  String get youHitMine => 'You hit a mine';

  @override
  String get playAgain => 'Play again';

  @override
  String get retry => 'Retry';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsPlayed => 'Played';

  @override
  String get statsWins => 'Wins';

  @override
  String get statsWinrate => 'Win rate';

  @override
  String get statsBestTime => 'Best time';

  @override
  String get statsEmpty => 'No games yet.\nPlay one and come back!';

  @override
  String winratePercent(int value) {
    return '$value%';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsSound => 'Sound effects';

  @override
  String get settingsMusic => 'Music';

  @override
  String get settingsGameplay => 'Gameplay';

  @override
  String get settingsVibration => 'Vibration';

  @override
  String get settingsInvertControls => 'Invert tap / flag';

  @override
  String get settingsInvertControlsDesc => 'Tap to flag; long-press to reveal.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get navStats => 'Statistics';

  @override
  String get navSettings => 'Settings';

  @override
  String get navShop => 'Shop';

  @override
  String get navAchievements => 'Achievements';

  @override
  String get navDaily => 'Daily Challenge';

  @override
  String get coinsLabel => 'Coins';

  @override
  String get shopTitle => 'Shop';

  @override
  String get shopTabItems => 'Items';

  @override
  String get shopTabBoards => 'Board';

  @override
  String get shopTabPieces => 'Pieces';

  @override
  String get shopBuy => 'Buy';

  @override
  String get shopEquip => 'Equip';

  @override
  String get shopEquipped => 'Equipped';

  @override
  String get shopOwned => 'Owned';

  @override
  String shopInStock(int count) {
    return 'In stock: $count';
  }

  @override
  String get shopNotEnough => 'Not enough coins';

  @override
  String get shopPurchased => 'Purchased!';

  @override
  String get shopEquippedMsg => 'Equipped';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String achievementsProgress(int unlocked, int total) {
    return '$unlocked/$total unlocked';
  }

  @override
  String achievementReward(int coins) {
    return '+$coins';
  }

  @override
  String get achievementUnlocked => 'Achievement unlocked!';

  @override
  String get dailyTitle => 'Daily Challenge';

  @override
  String get dailyTodayMode => 'Today\'s mode';

  @override
  String get dailyPlay => 'Play challenge';

  @override
  String get dailyDoneToday => 'Today\'s challenge complete!';

  @override
  String get dailyStreakLabel => 'Streak';

  @override
  String get dailyBestStreak => 'Best streak';

  @override
  String get dailyCompletedTotal => 'Completed';

  @override
  String streakDays(int days) {
    return '$days days';
  }

  @override
  String get dailyBadge => 'TODAY';

  @override
  String resultCoins(int coins) {
    return '+$coins coins';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/audio/audio_service.dart';
import 'core/haptics/haptics_service.dart';
import 'data/local/hive_service.dart';
import 'data/repositories/achievements_repository.dart';
import 'data/repositories/daily_repository.dart';
import 'data/repositories/economy_repository.dart';
import 'data/repositories/records_repository.dart';
import 'data/repositories/savegame_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'providers/achievements_provider.dart';
import 'providers/daily_provider.dart';
import 'providers/economy_provider.dart';
import 'providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientación bloqueada en portrait (plan §1). Los tableros grandes usan
  // zoom/pan, no rotación.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Persistencia lista antes de arrancar (plan §8.1). AdMob se inicializa en
  // Fase 3.
  final hive = HiveService();
  await hive.init();

  final settingsRepo = SettingsRepository(hive);
  final recordsRepo = RecordsRepository(hive);
  final economyRepo = EconomyRepository(hive);
  final achievementsRepo = AchievementsRepository(hive);
  final dailyRepo = DailyRepository(hive);
  final audio = AudioService();
  final haptics = HapticsService();

  runApp(
    MultiProvider(
      providers: [
        Provider<HiveService>.value(value: hive),
        Provider<SettingsRepository>.value(value: settingsRepo),
        Provider<RecordsRepository>.value(value: recordsRepo),
        Provider<SavegameRepository>(create: (_) => SavegameRepository(hive)),
        Provider<EconomyRepository>.value(value: economyRepo),
        Provider<AchievementsRepository>.value(value: achievementsRepo),
        Provider<DailyRepository>.value(value: dailyRepo),
        Provider<AudioService>.value(value: audio),
        Provider<HapticsService>.value(value: haptics),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(
            repo: settingsRepo,
            audio: audio,
            haptics: haptics,
          ),
        ),
        ChangeNotifierProvider<EconomyProvider>(
          create: (_) => EconomyProvider(economyRepo),
        ),
        ChangeNotifierProvider<DailyProvider>(
          create: (_) => DailyProvider(repo: dailyRepo),
        ),
        ChangeNotifierProvider<AchievementsProvider>(
          create: (_) => AchievementsProvider(
            repo: achievementsRepo,
            records: recordsRepo,
            economy: economyRepo,
            daily: dailyRepo,
          ),
        ),
      ],
      child: const MinexApp(),
    ),
  );
}
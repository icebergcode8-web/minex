import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/audio/audio_service.dart';
import 'core/haptics/haptics_service.dart';
import 'data/local/hive_service.dart';
import 'data/repositories/records_repository.dart';
import 'data/repositories/savegame_repository.dart';
import 'data/repositories/settings_repository.dart';
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
  final audio = AudioService();
  final haptics = HapticsService();

  runApp(
    MultiProvider(
      providers: [
        Provider<HiveService>.value(value: hive),
        Provider<SettingsRepository>.value(value: settingsRepo),
        Provider<RecordsRepository>(create: (_) => RecordsRepository(hive)),
        Provider<SavegameRepository>(create: (_) => SavegameRepository(hive)),
        Provider<AudioService>.value(value: audio),
        Provider<HapticsService>.value(value: haptics),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(
            repo: settingsRepo,
            audio: audio,
            haptics: haptics,
          ),
        ),
      ],
      child: const MinexApp(),
    ),
  );
}
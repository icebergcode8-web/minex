import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/local/hive_service.dart';
import 'data/repositories/records_repository.dart';
import 'data/repositories/settings_repository.dart';

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

  runApp(
    MultiProvider(
      providers: [
        Provider<HiveService>.value(value: hive),
        Provider<SettingsRepository>(create: (_) => SettingsRepository(hive)),
        Provider<RecordsRepository>(create: (_) => RecordsRepository(hive)),
      ],
      child: const MinexApp(),
    ),
  );
}

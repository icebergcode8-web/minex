import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:minex/core/audio/audio_service.dart';
import 'package:minex/core/constants/difficulty.dart';
import 'package:minex/core/constants/routes.dart';
import 'package:minex/core/haptics/haptics_service.dart';
import 'package:minex/data/local/hive_service.dart';
import 'package:minex/data/repositories/records_repository.dart';
import 'package:minex/data/repositories/settings_repository.dart';
import 'package:minex/l10n/app_localizations.dart';
import 'package:minex/ui/screens/custom_setup_screen.dart';
import 'package:minex/ui/screens/difficulty_select_screen.dart';
import 'package:minex/ui/screens/game_screen.dart';

class FakeRecordsRepository extends RecordsRepository {
  FakeRecordsRepository() : super(HiveService());
  @override
  int? bestTimeMs(Difficulty d) => null;
  @override
  int wins(Difficulty d) => 0;
  @override
  int played(Difficulty d) => 0;
  @override
  Future<bool> recordGame({
    required Difficulty difficulty,
    required bool won,
    required Duration elapsed,
  }) async =>
      false;
}

class FakeSettingsRepository extends SettingsRepository {
  FakeSettingsRepository() : super(HiveService());
  @override
  bool get invertControls => false;
}

Widget _wrap(Widget child) => MultiProvider(
      providers: [
        Provider<RecordsRepository>.value(value: FakeRecordsRepository()),
        Provider<SettingsRepository>.value(value: FakeSettingsRepository()),
        Provider<AudioService>.value(value: AudioService()),
        Provider<HapticsService>.value(value: HapticsService()),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  testWidgets('DifficultySelectScreen lista las 4 dificultades',
      (tester) async {
    await tester.pumpWidget(_wrap(const DifficultySelectScreen()));
    await tester.pump();
    expect(find.text('Fácil'), findsOneWidget);
    expect(find.text('Medio'), findsOneWidget);
    expect(find.text('Difícil'), findsOneWidget);
    expect(find.text('Experto'), findsOneWidget);
  });

  testWidgets('GameScreen pinta el tablero y responde a un toque',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        GameScreen(
          args: GameArgs(
            config: classicConfig(Difficulty.easy),
            difficulty: Difficulty.easy,
          ),
        ),
      ),
    );
    await tester.pump();
    // El HUD y la barra de acción están presentes.
    expect(find.text('Revelar'), findsOneWidget);
    // Un toque en el centro del tablero no debe lanzar excepción.
    await tester.tapAt(tester.getCenter(find.byType(GameScreen)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('el botón de bandera (toggle) no rompe la app', (tester) async {
    await tester.pumpWidget(
      _wrap(
        GameScreen(
          args: GameArgs(
            config: classicConfig(Difficulty.easy),
            difficulty: Difficulty.easy,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Revelar')); // toggle a modo bandera
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('Bandera'), findsOneWidget);
  });

  testWidgets('CustomSetupScreen muestra los tres controles', (tester) async {
    await tester.pumpWidget(_wrap(const CustomSetupScreen()));
    await tester.pump();
    expect(find.text('Filas'), findsOneWidget);
    expect(find.text('Columnas'), findsOneWidget);
    expect(find.text('Minas'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(3));
    // Mover un slider no debe romper ni violar la densidad máxima.
    await tester.drag(find.byType(Slider).first, const Offset(200, 0));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('el botón de pausa no rompe la app', (tester) async {
    await tester.pumpWidget(
      _wrap(
        GameScreen(
          args: GameArgs(
            config: classicConfig(Difficulty.easy),
            difficulty: Difficulty.easy,
          ),
        ),
      ),
    );
    await tester.pump();
    // Primero jugar (para estar en 'playing') y luego pausar.
    await tester.tapAt(tester.getCenter(find.byType(GameScreen)));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('Pausa'), findsOneWidget);
  });
}

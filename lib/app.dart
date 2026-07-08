import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/routes.dart';
import 'core/theme/app_theme.dart';
import 'domain/models/game_mode.dart';
import 'l10n/app_localizations.dart';
import 'providers/settings_provider.dart';
import 'ui/screens/custom_setup_screen.dart';
import 'ui/screens/difficulty_select_screen.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/mode_select_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/stats_screen.dart';

/// Raíz de la app: MaterialApp, temas claro/oscuro/sistema, idioma y rutas
/// (Navigator 1.0, plan §4.2). Escucha [SettingsProvider] para reaccionar a
/// cambios de tema e idioma en caliente.
class MinexApp extends StatelessWidget {
  const MinexApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      title: 'Minex',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: settings.locale,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      initialRoute: Routes.home,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.home:
        return _fade(const HomeScreen());
      case Routes.modeSelect:
        return _slide(const ModeSelectScreen());
      case Routes.difficulty:
        final mode = settings.arguments as GameMode? ?? GameMode.classic;
        return _slide(DifficultySelectScreen(mode: mode));
      case Routes.customSetup:
        return _slide(const CustomSetupScreen());
      case Routes.game:
        final args = settings.arguments as GameArgs;
        return _fadeScale(GameScreen(args: args));
      case Routes.stats:
        return _slide(const StatsScreen());
      case Routes.settings:
        return _slide(const SettingsScreen());
      default:
        return _fade(const HomeScreen());
    }
  }

  // ── Transiciones custom (plan §4.2) ────────────────────────────────
  PageRouteBuilder _fade(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, _) => page,
        transitionsBuilder: (_, a, _, child) =>
            FadeTransition(opacity: a, child: child),
      );

  PageRouteBuilder _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, _) => page,
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.18, 0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic))
                .animate(a),
            child: child,
          ),
        ),
      );

  PageRouteBuilder _fadeScale(Widget page) => PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, a, _) => page,
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: a,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOutCubic))
                .animate(a),
            child: child,
          ),
        ),
      );
}
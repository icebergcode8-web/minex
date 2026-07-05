import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/routes.dart';
import 'l10n/app_localizations.dart';
import 'ui/screens/difficulty_select_screen.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/home_screen.dart';

/// Raíz de la app: MaterialApp, temas y rutas (Navigator 1.0, plan §4.2).
class MinexApp extends StatelessWidget {
  const MinexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minex',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: _darkTheme,
      initialRoute: Routes.home,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.home:
        return _fade(const HomeScreen());
      case Routes.difficulty:
        return _slide(const DifficultySelectScreen());
      case Routes.game:
        final args = settings.arguments as GameArgs;
        return _fadeScale(GameScreen(args: args));
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
        transitionsBuilder: (_, a, _, child) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic))
              .animate(a),
          child: child,
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

final ThemeData _darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.bg,
  useMaterial3: true,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    error: AppColors.danger,
    surface: AppColors.bg,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    foregroundColor: AppColors.textPrimary,
  ),
);

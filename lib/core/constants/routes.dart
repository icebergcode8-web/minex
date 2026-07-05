import '../../domain/models/game_config.dart';
import 'difficulty.dart';

/// Nombres de ruta (Navigator 1.0 + onGenerateRoute, plan §4.2).
abstract final class Routes {
  static const home = '/';
  static const modeSelect = '/modes';
  static const difficulty = '/difficulty';
  static const game = '/game';
  static const stats = '/stats';
  static const settings = '/settings';
}

/// Argumentos para lanzar una partida.
class GameArgs {
  const GameArgs({required this.config, required this.difficulty});

  final GameConfig config;
  final Difficulty difficulty;
}

/// Estados de la máquina del juego (plan §6.5).
///
/// ```
/// idle → generating → playing ⇄ paused
///                       │
///                       ├── exploding → lost → (revive → playing)
///                       └── won
/// ```
enum GameStatus {
  idle,
  generating,
  playing,
  paused,
  exploding,
  lost,
  won,
}

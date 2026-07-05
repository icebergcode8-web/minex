/// Modos de juego de Minex (plan §2).
///
/// En Fase 1 solo se implementa [classic]; el resto se agregan en fases
/// posteriores pero se declaran aquí para que [GameConfig] y el engine sean
/// estables desde el inicio.
enum GameMode {
  classic,
  fog,
  blitz,
  liar,
  waves,
  tower,
  daily,
}

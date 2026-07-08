/// Puntaje y combos del modo Contrarreloj / Blitz (plan §2.3). **Lógica pura,
/// sin Flutter** (plan §6.3): el tiempo se inyecta como `nowMs`, así es 100%
/// determinista y testeable sin emulador.
///
/// Reglas (§2.3):
/// - El puntaje suma **celdas reveladas × multiplicador** + un bono por cada
///   **tablero completado**.
/// - Revelar celdas en rápida sucesión (dentro de [comboWindowMs]) llena la
///   barra de combo, que escala el multiplicador ×1 → ×2 → ×3 → ×5.
/// - Una pausa mayor a la ventana, o un error (mina), reinicia el combo a ×1.
class BlitzScoring {
  BlitzScoring({
    this.comboWindowMs = 1500,
    this.boardBonus = 25,
  });

  /// Ventana entre revelados para mantener el combo vivo.
  final int comboWindowMs;

  /// Puntos extra por completar un tablero.
  final int boardBonus;

  /// Umbrales de racha (celdas encadenadas) → multiplicador.
  /// `[0,1) → ×1`, `[5,12) → ×2`, `[12,22) → ×3`, `[22,∞) → ×5`.
  static const _tiers = <(int, int)>[(0, 1), (5, 2), (12, 3), (22, 5)];

  int _score = 0;
  int _boardsSolved = 0;
  int _comboCount = 0;
  int _lastRevealMs = -1;

  int get score => _score;
  int get boardsSolved => _boardsSolved;

  /// Celdas encadenadas en la racha actual.
  int get comboCount => _comboCount;

  /// Multiplicador actual (1, 2, 3 o 5).
  int get multiplier {
    var m = 1;
    for (final (threshold, mult) in _tiers) {
      if (_comboCount >= threshold) m = mult;
    }
    return m;
  }

  /// Progreso de la barra de combo hacia el siguiente escalón (0..1). En el
  /// último escalón se mantiene lleno.
  double get comboProgress {
    int? nextThreshold;
    var currentThreshold = 0;
    for (final (threshold, _) in _tiers) {
      if (_comboCount >= threshold) {
        currentThreshold = threshold;
      } else {
        nextThreshold = threshold;
        break;
      }
    }
    if (nextThreshold == null) return 1;
    final span = nextThreshold - currentThreshold;
    if (span <= 0) return 1;
    return ((_comboCount - currentThreshold) / span).clamp(0.0, 1.0);
  }

  /// Registra un lote de [cells] celdas reveladas en `nowMs`. Suma
  /// `cells × multiplicador` y actualiza la racha de combo.
  void registerReveal(int cells, int nowMs) {
    if (cells <= 0) return;
    final withinWindow =
        _lastRevealMs >= 0 && (nowMs - _lastRevealMs) <= comboWindowMs;
    _comboCount = withinWindow ? _comboCount + cells : cells;
    _lastRevealMs = nowMs;
    _score += cells * multiplier;
  }

  /// Registra un tablero completado: suma el bono y no rompe el combo.
  void registerBoardCleared() {
    _boardsSolved++;
    _score += boardBonus;
  }

  /// Un error (tocar mina) reinicia el combo, sin tocar el puntaje acumulado.
  void breakCombo() {
    _comboCount = 0;
    _lastRevealMs = -1;
  }

  void reset() {
    _score = 0;
    _boardsSolved = 0;
    _comboCount = 0;
    _lastRevealMs = -1;
  }
}
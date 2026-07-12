/// Una celda del tablero (plan §6.4).
///
/// Modelo mutable: el engine cambia [isRevealed]/[isFlagged] durante la
/// partida. La posición ([row]/[col]) y la presencia de mina son fijas una vez
/// generado el tablero.
class Cell {
  Cell({
    required this.row,
    required this.col,
    this.hasMine = false,
    this.isRevealed = false,
    this.isFlagged = false,
    this.adjacentMines = 0,
    this.displayedNumber,
    this.isLiar = false,
    this.minedBelow = false,
  });

  final int row;
  final int col;

  bool hasMine;
  bool isRevealed;
  bool isFlagged;

  /// Número real de minas adyacentes (0–8 en clásico).
  int adjacentMines;

  /// Número mostrado al jugador. Difiere de [adjacentMines] en modo Mentiroso
  /// (plan §2.4). En clásico es `null` y la UI usa [adjacentMines].
  int? displayedNumber;

  /// Modo Mentiroso: esta celda muestra un valor falso.
  bool isLiar;

  /// Modo 3D: la mina contada por esta celda está en la capa inferior
  /// (plan §2.6).
  bool minedBelow;

  /// Número que la UI debe pintar: el mostrado si existe, si no el real.
  int get shownNumber => displayedNumber ?? adjacentMines;

  /// `true` si es una celda vacía (sin minas alrededor) ya destapada.
  bool get isEmpty => !hasMine && adjacentMines == 0;

  /// Serializa la celda a un mapa compacto para el savegame (§6.2). `row`/`col`
  /// se omiten porque los deduce la posición en la grilla al restaurar. Solo se
  /// incluyen los campos que difieren del valor por defecto para ahorrar espacio.
  Map<String, dynamic> toMap() => {
        if (adjacentMines != 0) 'a': adjacentMines,
        if (hasMine) 'm': 1,
        if (isRevealed) 'r': 1,
        if (isFlagged) 'f': 1,
        if (displayedNumber != null) 'd': displayedNumber,
        if (isLiar) 'l': 1,
        if (minedBelow) 'b': 1,
      };

  /// Reconstruye una celda desde un mapa de [toMap], dadas su [row]/[col].
  factory Cell.fromMap(Map<String, dynamic> m, {required int row, required int col}) =>
      Cell(
        row: row,
        col: col,
        hasMine: m['m'] == 1,
        isRevealed: m['r'] == 1,
        isFlagged: m['f'] == 1,
        adjacentMines: (m['a'] as num?)?.toInt() ?? 0,
        displayedNumber: (m['d'] as num?)?.toInt(),
        isLiar: m['l'] == 1,
        minedBelow: m['b'] == 1,
      );
}

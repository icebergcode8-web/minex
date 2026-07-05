/// Formatea una duración como `mm:ss` (cronómetro del HUD).
String formatClock(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Formatea milisegundos como `mm:ss.d` (récords).
String formatRecord(int ms) {
  final d = Duration(milliseconds: ms);
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  final t = (d.inMilliseconds.remainder(1000) ~/ 100).toString();
  return '$m:$s.$t';
}

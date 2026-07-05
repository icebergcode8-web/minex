import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Efectos de sonido del juego (plan §5.3), con `audioplayers` de baja latencia.
///
/// Diseñado para ser **tolerante**: si un asset de audio aún no existe (los
/// `.mp3` se agregan más adelante) o falla la reproducción, se ignora el error
/// en vez de romper el juego. Se gatea con [sfxEnabled], sincronizado por
/// [SettingsProvider].
///
/// Los archivos esperados viven en `assets/audio/` (ver pubspec cuando se
/// incorporen). Mientras no existan, el servicio funciona como no-op silencioso.
enum Sfx { reveal, flag, explosion, victory, coin, tick, combo }

class AudioService {
  AudioService({this.sfxEnabled = true, this.musicEnabled = false});

  bool sfxEnabled;
  bool musicEnabled;

  /// Pool pequeño de players reutilizables para SFX solapados sin cortes.
  final List<AudioPlayer> _pool =
      List.generate(4, (i) => AudioPlayer(playerId: 'sfx_$i'));
  int _next = 0;

  static const _files = <Sfx, String>{
    Sfx.reveal: 'audio/reveal.mp3',
    Sfx.flag: 'audio/flag.mp3',
    Sfx.explosion: 'audio/explosion.mp3',
    Sfx.victory: 'audio/victory.mp3',
    Sfx.coin: 'audio/coin.mp3',
    Sfx.tick: 'audio/tick.mp3',
    Sfx.combo: 'audio/combo.mp3',
  };

  /// Reproduce un efecto. Nunca lanza: cualquier error (asset ausente, etc.)
  /// se traga en modo silencioso.
  Future<void> play(Sfx sfx) async {
    if (!sfxEnabled) return;
    final path = _files[sfx];
    if (path == null) return;
    try {
      final player = _pool[_next];
      _next = (_next + 1) % _pool.length;
      await player.stop();
      await player.play(AssetSource(path), volume: 0.8);
    } catch (e) {
      // Asset aún no incorporado o dispositivo sin salida de audio: no-op.
      if (kDebugMode) debugPrint('AudioService: sfx omitido ($sfx): $e');
    }
  }

  Future<void> dispose() async {
    for (final p in _pool) {
      await p.dispose();
    }
  }
}
import 'package:flutter_test/flutter_test.dart';
import 'package:minex/domain/engine/fog_engine.dart';

void main() {
  const fog = FogEngine(radius: 3, holdMs: 4000, fadeMs: 800);

  group('FogEngine.chebyshev', () {
    test('distancia rey: el máximo de las diferencias', () {
      expect(fog.chebyshev(0, 0, 0, 0), 0);
      expect(fog.chebyshev(0, 0, 2, 1), 2);
      expect(fog.chebyshev(5, 5, 2, 9), 4);
    });
  });

  group('FogEngine.brightness', () {
    test('con linterna todo es plenamente visible', () {
      expect(fog.brightness(distance: 99, sinceFocusMs: 99999, flashlightActive: true), 1);
    });

    test('fuera del radio: oscuridad', () {
      expect(fog.brightness(distance: 4, sinceFocusMs: 0), 0);
    });

    test('dentro del radio y dentro del hold: pleno brillo', () {
      expect(fog.brightness(distance: 3, sinceFocusMs: 0), 1);
      expect(fog.brightness(distance: 0, sinceFocusMs: 4000), 1);
    });

    test('a mitad del fade: brillo intermedio', () {
      final b = fog.brightness(distance: 1, sinceFocusMs: 4400); // 400/800
      expect(b, closeTo(0.5, 1e-9));
    });

    test('pasado el fade completo: oscuridad', () {
      expect(fog.brightness(distance: 0, sinceFocusMs: 4800), 0);
      expect(fog.brightness(distance: 0, sinceFocusMs: 9000), 0);
    });
  });
}
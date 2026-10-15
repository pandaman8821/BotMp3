import 'package:flutter_test/flutter_test.dart';
import 'package:botmp3/core/play_invariants.dart';

void main() {
  group('indiceValido', () {
    test('recorta al rango de la lista', () {
      expect(PlayInvariants.indiceValido(5, 10), 5);
      expect(PlayInvariants.indiceValido(-3, 10), 0);
      expect(PlayInvariants.indiceValido(99, 10), 9);
      expect(PlayInvariants.indiceValido(0, 0), -1);
    });
  });

  group('aceptarIndice (parpadeo de la primera cancion)', () {
    test('ignora el 0 que emite el motor mientras se espera el indice pedido', () {
      // Se pidio el indice 7 (cancion aleatoria) y el motor emite el 0: se ignora.
      expect(
        PlayInvariants.aceptarIndice(esperado: 7, recibido: 0),
        isFalse,
      );
      // Llega el indice que se pidio: se acepta.
      expect(
        PlayInvariants.aceptarIndice(esperado: 7, recibido: 7),
        isTrue,
      );
    });

    test('sin indice esperando, cualquier cambio se acepta', () {
      expect(PlayInvariants.aceptarIndice(esperado: null, recibido: 3), isTrue);
    });
  });

  group('debeContar (ranking)', () {
    test('no cuenta si no esta sonando', () {
      expect(
        PlayInvariants.debeContar(
          suena: false,
          indiceActual: 2,
          indiceContado: 2,
          ultimaRegistrada: null,
          id: 'a',
        ),
        isFalse,
      );
    });

    test('no cuenta si la cancion ya cambio de pista', () {
      expect(
        PlayInvariants.debeContar(
          suena: true,
          indiceActual: 3,
          indiceContado: 2,
          ultimaRegistrada: null,
          id: 'a',
        ),
        isFalse,
      );
    });

    test('no cuenta dos veces la misma cancion', () {
      expect(
        PlayInvariants.debeContar(
          suena: true,
          indiceActual: 2,
          indiceContado: 2,
          ultimaRegistrada: 'a',
          id: 'a',
        ),
        isFalse,
      );
    });

    test('cuenta una vez transcurridos los 20 s', () {
      expect(
        PlayInvariants.debeContar(
          suena: true,
          indiceActual: 2,
          indiceContado: 2,
          ultimaRegistrada: 'otra',
          id: 'a',
        ),
        isTrue,
      );
    });
  });
}
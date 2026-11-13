import 'package:flutter_test/flutter_test.dart';
import 'package:botmp3/services/library_service.dart';

/// El ranking debe sumar el registro reciente y el contador guardado, para que
/// ninguna cancion se quede a 0 y desaparezca de la lista.
void main() {
  test('combina registro y contador quedandose con el mayor', () {
    final Map<String, int> resultado = LibraryService.combinarConteos(
      <String, int>{'a': 2, 'b': 1},
      <String, int>{'a': 5, 'c': 3},
    );
    expect(resultado['a'], 5, reason: 'gana el contador guardado');
    expect(resultado['b'], 1, reason: 'solo esta en el registro');
    expect(resultado['c'], 3, reason: 'solo esta en el contador');
  });

  test('ignora contadores en cero o negativos', () {
    final Map<String, int> resultado = LibraryService.combinarConteos(
      <String, int>{'a': 1},
      <String, int>{'b': 0, 'c': -2},
    );
    expect(resultado.containsKey('b'), isFalse);
    expect(resultado.containsKey('c'), isFalse);
    expect(resultado['a'], 1);
  });

  test('sin datos devuelve vacio', () {
    expect(
      LibraryService.combinarConteos(<String, int>{}, <String, int>{}),
      isEmpty,
    );
  });
}

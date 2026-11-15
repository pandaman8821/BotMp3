import 'dart:convert';

import 'package:botmp3/core/text_utils.dart';
import 'package:flutter_test/flutter_test.dart';

/// El chat del Modo DJ enseñaba el JSON crudo de la IA
/// ({"mensaje": "...", "canciones": [...]}). Estas pruebas fijan que en el chat
/// y en la voz solo aparece la frase natural, venga como venga la respuesta.
void main() {
  const String frase = 'Seguimos en modo Big O y el rap urbano dominicano, con la energía subiendo.';
  final String djJson = jsonEncode(<String, Object>{
    'mensaje': frase,
    'canciones': <Map<String, String>>[
      <String, String>{'titulo': 'Indevolvible', 'artista': 'Big O', 'razon': 'Mismo flow.'},
    ],
  });

  test('JSON normal del DJ: solo se ve la frase', () {
    expect(textoParaChat(djJson), frase);
  });

  test('JSON metido dentro de "mensaje" (el caso de la captura): solo la frase', () {
    final String anidado = jsonEncode(<String, String>{'mensaje': djJson});
    final String resultado = textoParaChat(anidado);
    expect(resultado, frase);
    expect(resultado.contains('{'), isFalse);
    expect(resultado.contains('canciones'), isFalse);
  });

  test('JSON cortado por el límite de tokens: se rescata la frase', () {
    final String cortado = djJson.substring(0, djJson.indexOf('"titulo"') + 12);
    final String resultado = textoParaChat(cortado);
    expect(resultado, frase);
  });

  test('JSON envuelto en un bloque de código: solo la frase', () {
    expect(textoParaChat('```json\n$djJson\n```'), frase);
  });

  test('Una respuesta normal de chat se limpia de markdown y se queda igual', () {
    expect(textoParaChat('Te pongo **Indevolvible** de Big O.'), 'Te pongo Indevolvible de Big O.');
  });

  test('Las órdenes internas nunca se ven', () {
    final String resultado = textoParaChat('Listo, a sonar.\n<CMD>{"accion":"play"}</CMD>');
    expect(resultado, 'Listo, a sonar.');
  });
}

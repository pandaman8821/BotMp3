import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Comprueba que los 12 idiomas tengan exactamente las mismas claves que el
/// ingles y que los marcadores {x} coincidan: evita textos rotos al traducir.
void main() {
  final Directory base = Directory('lib/l10n');

  Map<String, dynamic> leer(String idioma) {
    final File f = File('${base.path}/app_$idioma.arb');
    return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  }

  test('todos los idiomas tienen las mismas claves que ingles', () {
    final Map<String, dynamic> en = leer('en');
    final List<String> claves = en.keys.where((String k) => !k.startsWith('@')).toList();
    const List<String> idiomas = <String>[
      'es', 'pt', 'pt_BR', 'zh', 'zh_CN', 'ja', 'ko', 'de', 'fr', 'it', 'hi',
    ];
    for (final String idioma in idiomas) {
      final Map<String, dynamic> datos = leer(idioma);
      final List<String> faltan =
          claves.where((String k) => !datos.containsKey(k)).toList();
      expect(faltan, isEmpty, reason: 'faltan en $idioma: $faltan');
    }
  });

  test('los marcadores de los textos coinciden en todos los idiomas', () {
    final Map<String, dynamic> en = leer('en');
    final RegExp marcador = RegExp(r'\{(\w+)\}');
    const List<String> idiomas = <String>[
      'es', 'pt', 'pt_BR', 'zh', 'zh_CN', 'ja', 'ko', 'de', 'fr', 'it', 'hi',
    ];
    for (final String idioma in idiomas) {
      final Map<String, dynamic> datos = leer(idioma);
      for (final MapEntry<String, dynamic> e in en.entries) {
        if (e.key.startsWith('@') || e.value is! String) continue;
        final Set<String> esperados =
            marcador.allMatches(e.value as String).map((Match m) => m.group(1)!).toSet();
        if (esperados.isEmpty) continue;
        final dynamic valor = datos[e.key];
        final Set<String> actuales = marcador
            .allMatches(valor is String ? valor : '')
            .map((Match m) => m.group(1)!)
            .toSet();
        expect(actuales, esperados, reason: '${e.key} en $idioma');
      }
    }
  });
}
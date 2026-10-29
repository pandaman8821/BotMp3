import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants.dart';

/// Descarga el catalogo REAL de modelos de cada proveedor de IA y lo cachea,
/// para que la app no ofrezca modelos retirados (como paso con gemini-1.5) ni
/// se quede sin los nuevos. Si falla, se mantiene la lista fija de reserva.
class ModelCatalog {
  const ModelCatalog._();

  static Future<void> actualizar(AiProvider proveedor, String clave) async {
    try {
      final List<String>? modelos = await _descargar(proveedor, clave);
      if (modelos != null && modelos.isNotEmpty) {
        AudioFormats.cacheModelos[proveedor.name] = modelos;
      }
    } catch (_) {
      // Sin red o clave invalida: se usara la lista de reserva.
    }
  }

  static Future<List<String>?> _descargar(AiProvider proveedor, String clave) async {
    if (clave.trim().isEmpty) return null;
    switch (proveedor) {
      case AiProvider.openai:
        return _listaOpenAi('https://api.openai.com/v1/models', clave, soloChat: true);
      case AiProvider.deepseek:
        return _listaOpenAi('https://api.deepseek.com/v1/models', clave, soloChat: false);
      case AiProvider.gemini:
        return _listaGemini(clave);
      case AiProvider.claude:
        return _listaClaude(clave);
    }
  }

  static Future<List<String>?> _listaOpenAi(
    String url,
    String clave, {
    required bool soloChat,
  }) async {
    final http.Response r = await http
        .get(Uri.parse(url), headers: <String, String>{'Authorization': 'Bearer ' + clave})
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) return null;
    final dynamic json = jsonDecode(r.body);
    final List<dynamic>? datos = (json is Map ? json['data'] : null) as List<dynamic>?;
    if (datos == null) return null;
    final List<String> ids = <String>[];
    for (final dynamic m in datos) {
      if (m is! Map<String, dynamic>) continue;
      final String id = (m['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final String bajo = id.toLowerCase();
      if (bajo.contains('embedding')) continue;
      if (soloChat && !(bajo.startsWith('gpt') || bajo.startsWith('o1') || bajo.startsWith('o3') || bajo.startsWith('o4'))) continue;
      ids.add(id);
    }
    ids.sort();
    return ids;
  }

  static Future<List<String>?> _listaGemini(String clave) async {
    final Uri uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models')
        .replace(queryParameters: <String, String>{'key': clave});
    final http.Response r = await http.get(uri).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) return null;
    final dynamic json = jsonDecode(r.body);
    final List<dynamic>? datos = (json is Map ? json['models'] : null) as List<dynamic>?;
    if (datos == null) return null;
    final List<String> nombres = <String>[];
    for (final dynamic m in datos) {
      if (m is! Map<String, dynamic>) continue;
      final List<dynamic> metodos = (m['supportedGenerationMethods'] as List<dynamic>?) ?? <dynamic>[];
      if (!metodos.contains('generateContent')) continue;
      final String nombre = (m['name'] ?? '').toString().replaceFirst('models/', '');
      if (nombre.isNotEmpty) nombres.add(nombre);
    }
    nombres.sort();
    return nombres;
  }

  static Future<List<String>?> _listaClaude(String clave) async {
    final http.Response r = await http.get(
      Uri.parse('https://api.anthropic.com/v1/models'),
      headers: <String, String>{'x-api-key': clave, 'anthropic-version': '2023-06-01'},
    ).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) return null;
    final dynamic json = jsonDecode(r.body);
    final List<dynamic>? datos = (json is Map ? json['data'] : null) as List<dynamic>?;
    if (datos == null) return null;
    final List<String> ids = <String>[];
    for (final dynamic m in datos) {
      if (m is! Map<String, dynamic>) continue;
      final String id = (m['id'] ?? '').toString();
      if (id.isNotEmpty) ids.add(id);
    }
    return ids;
  }
}
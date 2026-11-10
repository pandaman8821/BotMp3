import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';

/// Descubre los modelos que cada proveedor ofrece **hoy** en su API y los deja
/// ordenados con los **gratuitos primero**.
///
/// Los modelos cambian cada semana, así que la lista fija del código es solo
/// el respaldo: en cuanto se descarga el catálogo real, manda el real.
/// Todo es best-effort: si no hay red o la clave falla, se usa la lista fija y
/// la app sigue funcionando igual.
class ModelCatalogService {
  ModelCatalogService._();

  static ModelCatalogService? _instancia;

  static ModelCatalogService get instance => _instancia ??= ModelCatalogService._();

  static const String _claveDatos = 'catalogo_modelos_v1';
  static const String _claveFecha = 'catalogo_modelos_fecha_v1';

  /// Se refresca solo cuando pasan estos días.
  static const Duration vigencia = Duration(days: 3);

  /// Filtros: nada de modelos que no sirven para conversar.
  static const List<String> _excluidos = <String>[
    'embedding',
    'embed',
    'aqa',
    'imagen',
    'image',
    'tts',
    'audio',
    'speech',
    'moderation',
    'whisper',
    'realtime',
    'vision',
    'transcribe',
    'bison',
    'gecko',
    'dall',
    'sora',
    'learnlm',
  ];

  /// Carga el catálogo guardado en memoria (sin red).
  Future<void> cargar() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? crudo = prefs.getString(_claveDatos);
      if (crudo == null || crudo.isEmpty) return;
      final Map<String, dynamic> mapa = jsonDecode(crudo) as Map<String, dynamic>;
      mapa.forEach((String id, dynamic lista) {
        final List<String> valores = (lista as List<dynamic>)
            .map((dynamic e) => e.toString())
            .where((String v) => v.isNotEmpty)
            .toList();
        if (valores.isNotEmpty) AudioFormats.cacheModelos[id] = valores;
      });
    } catch (error) {
      debugPrint('Catalogo de modelos: no se pudo leer el cache ($error)');
    }
  }

  /// ¿Hace más de [vigencia] que no se actualiza?
  Future<bool> get desactualizado async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? guardado = prefs.getInt(_claveFecha);
    if (guardado == null) return true;
    final DateTime fecha = DateTime.fromMillisecondsSinceEpoch(guardado);
    return DateTime.now().difference(fecha) > vigencia;
  }

  /// Descarga la lista real del proveedor y la guarda. Devuelve cuántos modelos.
  Future<int> actualizar(
    AiProvider provider,
    String apiKey, {
    http.Client? cliente,
  }) async {
    final http.Client http_ = cliente ?? http.Client();
    try {
      final List<String> crudos = await _descargar(provider, apiKey, http_);
      if (crudos.isEmpty) return 0;
      final List<String> limpios = _limpiar(crudos);
      final List<String> ordenados = ordenar(provider, limpios);
      if (ordenados.isEmpty) return 0;
      AudioFormats.cacheModelos[provider.id] = ordenados;
      await _guardar();
      return ordenados.length;
    } finally {
      if (cliente == null) http_.close();
    }
  }

  /// Actualiza solo los proveedores con clave y solo si el cache está viejo.
  ///
  /// Nunca lanza: cualquier fallo se ignora para no molestar al usuario.
  Future<int> actualizarSiHaceFalta(Map<AiProvider, String> claves) async {
    if (claves.isEmpty) return 0;
    int total = 0;
    for (final MapEntry<AiProvider, String> entrada in claves.entries) {
      try {
        total += await actualizar(entrada.key, entrada.value);
      } catch (error) {
        debugPrint('Catalogo de modelos (${entrada.key.id}): $error');
      }
    }
    return total;
  }

  // ------------------------------------------------------------------ red

  Future<List<String>> _descargar(
    AiProvider provider,
    String apiKey,
    http.Client cliente,
  ) async {
    final String key = apiKey.trim();
    if (key.isEmpty) return const <String>[];
    const Duration espera = Duration(seconds: 20);

    switch (provider) {
      case AiProvider.gemini:
        final Uri uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models'
          '?key=$key&pageSize=200',
        );
        final http.Response r = await cliente.get(uri).timeout(espera);
        if (r.statusCode != 200) return const <String>[];
        final Map<String, dynamic> json = jsonDecode(r.body) as Map<String, dynamic>;
        final List<dynamic> lista = (json['models'] as List<dynamic>?) ?? const <dynamic>[];
        return lista
            .whereType<Map<String, dynamic>>()
            .where((Map<String, dynamic> m) {
              final List<dynamic> metodos =
                  (m['supportedGenerationMethods'] as List<dynamic>?) ?? const <dynamic>[];
              return metodos.isEmpty || metodos.contains('generateContent');
            })
            .map((Map<String, dynamic> m) => (m['name'] ?? '').toString())
            .toList();

      case AiProvider.openai:
        final http.Response r = await cliente.get(
          Uri.parse('https://api.openai.com/v1/models'),
          headers: <String, String>{'Authorization': 'Bearer $key'},
        ).timeout(espera);
        if (r.statusCode != 200) return const <String>[];
        final Map<String, dynamic> json = jsonDecode(r.body) as Map<String, dynamic>;
        final List<dynamic> lista = (json['data'] as List<dynamic>?) ?? const <dynamic>[];
        return lista
            .whereType<Map<String, dynamic>>()
            .map((Map<String, dynamic> m) => (m['id'] ?? '').toString())
            .toList();

      case AiProvider.deepseek:
        final http.Response r = await cliente.get(
          Uri.parse('https://api.deepseek.com/models'),
          headers: <String, String>{'Authorization': 'Bearer $key'},
        ).timeout(espera);
        if (r.statusCode != 200) return const <String>[];
        final Map<String, dynamic> json = jsonDecode(r.body) as Map<String, dynamic>;
        final List<dynamic> lista = (json['data'] as List<dynamic>?) ?? const <dynamic>[];
        return lista
            .whereType<Map<String, dynamic>>()
            .map((Map<String, dynamic> m) => (m['id'] ?? '').toString())
            .toList();

      case AiProvider.claude:
        final http.Response r = await cliente.get(
          Uri.parse('https://api.anthropic.com/v1/models?limit=100'),
          headers: <String, String>{
            'x-api-key': key,
            'anthropic-version': '2023-06-01',
          },
        ).timeout(espera);
        if (r.statusCode != 200) return const <String>[];
        final Map<String, dynamic> json = jsonDecode(r.body) as Map<String, dynamic>;
        final List<dynamic> lista = (json['data'] as List<dynamic>?) ?? const <dynamic>[];
        return lista
            .whereType<Map<String, dynamic>>()
            .map((Map<String, dynamic> m) => (m['id'] ?? '').toString())
            .toList();
    }
  }

  // -------------------------------------------------------------- limpieza

  List<String> _limpiar(List<String> crudos) {
    final Set<String> vistos = <String>{};
    final List<String> salida = <String>[];
    for (String crudo in crudos) {
      String valor = crudo.trim();
      if (valor.startsWith('models/')) valor = valor.substring(7);
      if (valor.isEmpty) continue;
      final String minus = valor.toLowerCase();
      if (_excluidos.any(minus.contains)) continue;
      if (!vistos.add(minus)) continue;
      salida.add(valor);
    }
    return salida;
  }

  /// Ordena dejando **primero los gratuitos** y, dentro de cada grupo, los
  /// nombres más nuevos primero (gemini-2.5 antes que gemini-2.0).
  List<String> ordenar(AiProvider provider, List<String> modelos) {
    final List<String> copia = List<String>.from(modelos);
    copia.sort((String a, String b) {
      final int gratisA = esModeloGratis(provider, a) ? 0 : 1;
      final int gratisB = esModeloGratis(provider, b) ? 0 : 1;
      if (gratisA != gratisB) return gratisA.compareTo(gratisB);
      return b.toLowerCase().compareTo(a.toLowerCase());
    });
    return copia;
  }

  Future<void> _guardar() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, List<String>> mapa = <String, List<String>>{};
    AudioFormats.cacheModelos.forEach((String id, List<String> lista) {
      if (lista.isNotEmpty) mapa[id] = lista;
    });
    await prefs.setString(_claveDatos, jsonEncode(mapa));
    await prefs.setInt(_claveFecha, DateTime.now().millisecondsSinceEpoch);
  }
}

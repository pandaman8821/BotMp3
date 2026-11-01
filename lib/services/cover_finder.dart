import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Busca carátulas en internet cuando el archivo no trae ninguna.
///
/// Fuentes gratuitas y sin clave: iTunes Search (Apple) y Deezer.
/// Solo se envían título y artista; no se envía nada más.
class CoverFinder {
  const CoverFinder._();

  static const Map<String, String> _cabeceras = <String, String>{
    'User-Agent': 'BotMp3/1.9 (offline music player)',
    'Accept': 'application/json',
  };

  /// Devuelve los bytes de la mejor carátula encontrada, o null.
  /// [source] recibe el nombre de la fuente usada ("iTunes" o "Deezer").
  static Future<Uint8List?> search(
    String title,
    String artist, {
    void Function(String source)? onSource,
  }) async {
    final String consulta = '$artist $title'.trim();
    if (consulta.isEmpty) return null;

    final Uint8List? deItunes = await _itunes(consulta);
    if (deItunes != null) {
      onSource?.call('iTunes');
      return deItunes;
    }
    final Uint8List? deDeezer = await _deezer(consulta);
    if (deDeezer != null) {
      onSource?.call('Deezer');
      return deDeezer;
    }
    return null;
  }

  static Future<Uint8List?> _itunes(String consulta) async {
    try {
      final Uri uri = Uri.https('itunes.apple.com', '/search', <String, String>{
        'term': consulta,
        'media': 'music',
        'entity': 'song',
        'limit': '5',
      });
      final http.Response r = await http
          .get(uri, headers: _cabeceras)
          .timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return null;
      final dynamic datos = jsonDecode(r.body);
      if (datos is! Map) return null;
      final dynamic resultados = datos['results'];
      if (resultados is! List || resultados.isEmpty) return null;
      for (final dynamic item in resultados) {
        if (item is! Map) continue;
        final Object? arte = item['artworkUrl100'] ?? item['artworkUrl60'];
        if (arte == null) continue;
        final String url = arte
            .toString()
            .replaceAll('100x100', '600x600')
            .replaceAll('60x60', '600x600');
        final Uint8List? bytes = await _descargar(url);
        if (bytes != null) return bytes;
      }
    } catch (_) {}
    return null;
  }

  static Future<Uint8List?> _deezer(String consulta) async {
    try {
      final Uri uri = Uri.https('api.deezer.com', '/search', <String, String>{
        'q': consulta,
        'limit': '5',
      });
      final http.Response r = await http
          .get(uri, headers: _cabeceras)
          .timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return null;
      final dynamic datos = jsonDecode(r.body);
      if (datos is! Map) return null;
      final dynamic lista = datos['data'];
      if (lista is! List || lista.isEmpty) return null;
      for (final dynamic item in lista) {
        if (item is! Map) continue;
        final dynamic album = item['album'];
        if (album is! Map) continue;
        final Object? arte = album['cover_xl'] ?? album['cover_big'];
        if (arte == null) continue;
        final Uint8List? bytes = await _descargar(arte.toString());
        if (bytes != null) return bytes;
      }
    } catch (_) {}
    return null;
  }

  static Future<Uint8List?> _descargar(String url) async {
    try {
      final http.Response r = await http
          .get(Uri.parse(url), headers: _cabeceras)
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200 || r.bodyBytes.length < 2048) return null;
      return r.bodyBytes;
    } catch (_) {
      return null;
    }
  }
}
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Descarga letras desde LRCLIB (API publica, gratuita y sin clave).
///
/// Solo se envian titulo y artista. El resultado se guarda en cache para no
/// repetir la peticion cuando se vuelve a abrir la misma cancion.
class LyricsFetcher {
  const LyricsFetcher._();

  static final Map<String, String> _memoria = <String, String>{};

  static String _clave(String titulo, String artista) =>
      '${titulo.toLowerCase().trim()}|${artista.toLowerCase().trim()}';

  static Future<File?> _archivoCache(String clave) async {
    try {
      final Directory base = await getApplicationCacheDirectory();
      final Directory dir = Directory('${base.path}/lyrics');
      if (!await dir.exists()) await dir.create(recursive: true);
      final String nombre = clave.hashCode.toRadixString(16);
      return File('${dir.path}/$nombre.lrc');
    } catch (_) {
      return null;
    }
  }

  /// Devuelve la letra (con tiempos LRC si existe) o null.
  static Future<String?> fetch(String titulo, String artista, {String album = ''}) async {
    final String clave = _clave(titulo, artista);
    if (_memoria.containsKey(clave)) return _memoria[clave];

    final File? cache = await _archivoCache(clave);
    try {
      if (cache != null && await cache.exists()) {
        final String guardada = await cache.readAsString();
        if (guardada.trim().isNotEmpty) {
          _memoria[clave] = guardada;
          return guardada;
        }
      }
    } catch (_) {}

    try {
      final Uri uri = Uri.https('lrclib.net', '/api/search', <String, String>{
        'track_name': titulo,
        'artist_name': artista,
        if (album.trim().isNotEmpty) 'album_name': album,
      });
      final http.Response r = await http.get(uri, headers: <String, String>{
        'User-Agent': 'BotMp3/1.9 (offline music player)',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return null;
      final dynamic datos = jsonDecode(r.body);
      if (datos is! List) return null;
      for (final dynamic item in datos) {
        if (item is! Map) continue;
        final Object? letra = item['syncedLyrics'] ?? item['plainLyrics'];
        if (letra == null) continue;
        final String texto = letra.toString();
        if (texto.trim().isEmpty) continue;
        _memoria[clave] = texto;
        try { if (cache != null) await cache.writeAsString(texto); } catch (_) {}
        return texto;
      }
    } catch (_) {}
    return null;
  }
}

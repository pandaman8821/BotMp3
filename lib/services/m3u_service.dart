import '../models/song.dart';

/// Importacion y exportacion de listas en formato M3U/M3U8.
class M3uService {
  const M3uService._();

  /// Genera el contenido M3U de una lista de canciones.
  static String generar(List<Song> canciones) {
    final StringBuffer buffer = StringBuffer('#EXTM3U\n');
    for (final Song s in canciones) {
      final int seg = (s.durationMs / 1000).round();
      buffer.writeln('#EXTINF:$seg,${s.artist} - ${s.title}');
      buffer.writeln(s.path);
    }
    return buffer.toString();
  }

  /// Resuelve las rutas de un M3U contra la biblioteca (por ruta o por nombre).
  static List<Song> resolver(String contenido, List<Song> biblioteca) {
    final Map<String, Song> porRuta = <String, Song>{};
    final Map<String, Song> porNombre = <String, Song>{};
    for (final Song s in biblioteca) {
      porRuta[s.path] = s;
      final int corte = s.path.lastIndexOf(RegExp(r'[\\/]'));
      final String nombre = corte >= 0 ? s.path.substring(corte + 1) : s.path;
      porNombre[nombre.toLowerCase()] = s;
    }
    final List<Song> salida = <Song>[];
    final Set<String> vistos = <String>{};
    for (final String linea in contenido.split('\n')) {
      final String limpia = linea.trim();
      if (limpia.isEmpty || limpia.startsWith('#')) continue;
      Song? encontrada = porRuta[limpia];
      if (encontrada == null) {
        final int corte = limpia.lastIndexOf(RegExp(r'[\\/]'));
        final String nombre = corte >= 0 ? limpia.substring(corte + 1) : limpia;
        encontrada = porNombre[nombre.toLowerCase()];
      }
      if (encontrada != null && vistos.add(encontrada.id)) salida.add(encontrada);
    }
    return salida;
  }
}
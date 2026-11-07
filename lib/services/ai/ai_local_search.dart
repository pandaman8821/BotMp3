import '../../core/formatters.dart';
import '../../models/song.dart';

/// Busqueda local para dar contexto REAL a la IA.
///
/// La IA antes solo recibia las canciones mas escuchadas; si el artista tenia
/// 0 reproducciones, respondia que no existia. Con esto, la IA recibe las
/// coincidencias exactas y el indice de artistas: la biblioteca manda.
class AiLocalSearch {
  const AiLocalSearch._();

  /// Coincidencias de [consulta] en la biblioteca, ordenadas por relevancia.
  static List<Song> buscar(List<Song> canciones, String consulta, {int limit = 30}) {
    final String q = Formatters.normalize(consulta).trim();
    if (q.isEmpty) return const <Song>[];
    final List<String> palabras = q
        .split(RegExp(r'\s+'))
        .where((String p) => p.length > 1)
        .toList(growable: false);
    final List<(Song, double)> puntuadas = <(Song, double)>[];
    for (final Song s in canciones) {
      final List<String> campos = <String>[
        s.title,
        s.artist,
        s.album,
        s.genre,
        s.tags.join(' '),
      ].map(Formatters.normalize).toList(growable: false);
      double score = 0;
      for (final String campo in campos) {
        if (campo == q) {
          score += 3;
        } else if (campo.contains(q)) {
          score += 2;
        } else {
          for (final String palabra in palabras) {
            if (campo.contains(palabra)) score += 0.7;
          }
        }
      }
      if (score > 0) puntuadas.add((s, score));
    }
    puntuadas.sort(((Song, double) a, (Song, double) b) => b.$2.compareTo(a.$2));
    return puntuadas.take(limit).map(((Song, double) e) => e.$1).toList(growable: false);
  }

  /// Indice compacto de artistas de la biblioteca (para que la IA sepa quien hay).
  static String artistas(List<Song> canciones, {int limit = 250}) {
    final Set<String> nombres = <String>{};
    for (final Song s in canciones) {
      final String a = s.artist.trim();
      if (a.isNotEmpty) nombres.add(a);
    }
    if (nombres.isEmpty) return 'Sin artistas.';
    final List<String> ordenados = nombres.toList()..sort((String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ordenados.take(limit).join(' | ');
  }

  /// Bloque de contexto que se le pasa a la IA antes de responder.
  static String contexto(List<Song> canciones, String consulta) {
    final List<Song> coincidencias = buscar(canciones, consulta);
    final StringBuffer b = StringBuffer();
    b.writeln('TOTAL DE CANCIONES EN LA BIBLIOTECA: ${canciones.length}');
    b.writeln('ARTISTAS DE LA BIBLIOTECA: ${artistas(canciones)}');
    if (coincidencias.isEmpty) {
      b.writeln('COINCIDENCIAS para "$consulta": ninguna.');
    } else {
      b.writeln('COINCIDENCIAS para "$consulta" (${coincidencias.length}):');
      for (final Song s in coincidencias) {
        b.writeln('- ${s.artist} - ${s.title}${s.album.isEmpty ? '' : ' [${s.album}]'}');
      }
    }
    return b.toString();
  }
}
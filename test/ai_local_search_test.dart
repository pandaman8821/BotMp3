import 'package:flutter_test/flutter_test.dart';
import 'package:botmp3/models/song.dart';
import 'package:botmp3/services/ai/ai_local_search.dart';

Song _song(String titulo, String artista, {int reproducciones = 0}) => Song(
      id: '$titulo-$artista',
      path: '/music/$artista - $titulo.mp3',
      title: titulo,
      artist: artista,
      album: 'Album de $artista',
      year: 2023,
      genre: 'Rock',
      durationMs: 180000,
      playCount: reproducciones,
    );

void main() {
  group('Busqueda local para la IA', () {
    final List<Song> biblioteca = <Song>[
      _song('BABY SAID', 'Maneskin'),
      _song('BLA BLA BLA', 'Maneskin'),
      _song('Lapiz Conciente', 'Don Miguelo', reproducciones: 500),
      _song('Canserbero', 'Jeremias', reproducciones: 300),
    ];

    test('encuentra canciones con 0 reproducciones (el bug de la IA)', () {
      final List<Song> halladas = AiLocalSearch.buscar(biblioteca, 'maneskin');
      expect(halladas, isNotEmpty);
      expect(halladas.every((Song s) => s.artist == 'Maneskin'), isTrue);
      expect(halladas.length, 2);
    });

    test('no depende de acentos ni mayusculas', () {
      expect(AiLocalSearch.buscar(biblioteca, 'MÅNESKIN'), isNotEmpty);
      expect(AiLocalSearch.buscar(biblioteca, 'maneskin'), isNotEmpty);
    });

    test('el indice de artistas incluye al artista aunque tenga 0 reproducciones', () {
      expect(AiLocalSearch.artistas(biblioteca), contains('Maneskin'));
    });

    test('el contexto de la IA incluye las coincidencias y el total', () {
      final String ctx = AiLocalSearch.contexto(biblioteca, 'maneskin');
      expect(ctx, contains('TOTAL DE CANCIONES EN LA BIBLIOTECA: 4'));
      expect(ctx, contains('Maneskin'));
      expect(ctx, contains('BABY SAID'));
    });

    test('consulta vacia no devuelve nada', () {
      expect(AiLocalSearch.buscar(biblioteca, '   '), isEmpty);
    });
  });
}
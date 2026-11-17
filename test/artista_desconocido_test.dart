import 'package:botmp3/models/song.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

Song _cancion(String artista) => Song(
      id: 'x',
      path: '/x.mp3',
      title: 'Dale Don Dale',
      artist: artista,
      album: '',
      year: 0,
      genre: 'Pop',
      durationMs: 0,
    );

void main() {
  tearDown(() => Intl.defaultLocale = null);

  test('el texto guardado en espanol se muestra en ingles con la app en ingles', () {
    Intl.defaultLocale = 'en';
    expect(_cancion('Artista desconocido').artistLabel, 'Unknown artist');
    expect(_cancion('').artistLabel, 'Unknown artist');
    expect(_cancion('<unknown>').artistLabel, 'Unknown artist');
  });

  test('cualquier marcador se traduce al idioma activo', () {
    Intl.defaultLocale = 'de';
    expect(_cancion('Unknown artist').artistLabel, 'Unbekannter Künstler');
    Intl.defaultLocale = 'es';
    expect(_cancion('未知艺术家').artistLabel, 'Artista desconocido');
  });

  test('un artista real no se toca', () {
    Intl.defaultLocale = 'en';
    final Song s = _cancion('Don Omar');
    expect(s.artistLabel, 'Don Omar');
    expect(s.artistaDesconocido, isFalse);
    expect(s.subtitle, 'Don Omar');
  });

  test('el subtitulo usa la etiqueta traducida', () {
    Intl.defaultLocale = 'fr';
    expect(_cancion('Artista desconocido').subtitle, 'Artiste inconnu');
  });
}

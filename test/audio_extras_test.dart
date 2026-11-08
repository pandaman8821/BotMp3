import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:botmp3/services/bookmarks_service.dart';
import 'package:botmp3/services/replay_gain.dart';

Uint8List _bytes(String texto) => Uint8List.fromList(utf8.encode(texto));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Marcadores de cancion', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('agrega, ordena y devuelve marcadores', () async {
      final BookmarksService s = BookmarksService.instance;
      await s.agregar('cancion1', const Duration(seconds: 90));
      await s.agregar('cancion1', const Duration(seconds: 30));
      final List<Duration> marcas = await s.de('cancion1');
      expect(marcas.length, 2);
      expect(marcas.first.inSeconds, 30);
      expect(marcas.last.inSeconds, 90);
    });

    test('ignora duplicados en el mismo segundo', () async {
      final BookmarksService s = BookmarksService.instance;
      await s.agregar('cancion2', const Duration(seconds: 40));
      await s.agregar('cancion2', const Duration(milliseconds: 40400));
      expect((await s.de('cancion2')).length, 1);
    });

    test('quita un marcador y limpia la cancion', () async {
      final BookmarksService s = BookmarksService.instance;
      await s.agregar('cancion3', const Duration(seconds: 10));
      await s.agregar('cancion3', const Duration(seconds: 20));
      await s.quitar('cancion3', const Duration(seconds: 10));
      expect((await s.de('cancion3')).length, 1);
      await s.limpiar('cancion3');
      expect(await s.de('cancion3'), isEmpty);
    });

    test('cada cancion tiene sus propios marcadores', () async {
      final BookmarksService s = BookmarksService.instance;
      await s.agregar('a', const Duration(seconds: 5));
      await s.agregar('b', const Duration(seconds: 7));
      expect((await s.de('a')).single.inSeconds, 5);
      expect((await s.de('b')).single.inSeconds, 7);
    });
  });

  group('ReplayGain en OGG y M4A', () {
    test('lee la etiqueta en texto plano (OGG/Opus)', () {
      final Uint8List datos = _bytes('OggS....ARTIST=Maneskin....replaygain_track_gain=-7.5 dB....');
      expect(ReplayGain.gainDeBinario(datos), closeTo(-7.5, 0.01));
    });

    test('lee la etiqueta de iTunes en M4A', () {
      final Uint8List datos = _bytes('....freeform....replaygain_track_gain=+3.0 dB....');
      expect(ReplayGain.gainDeBinario(datos), closeTo(3.0, 0.01));
    });

    test('sin etiqueta devuelve null', () {
      expect(ReplayGain.gainDeBinario(_bytes('solo audio sin etiquetas')), isNull);
    });
  });
}
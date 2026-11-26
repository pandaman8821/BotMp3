import 'dart:math';

import 'package:botmp3/models/song.dart';
import 'package:botmp3/services/player_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// El modo aleatorio repetía canciones porque el motor de audio seguía el
/// orden de la biblioteca. Ahora se baraja la cola misma: estas pruebas fijan
/// que cada pasada es una permutación sin repetidas.
List<Song> _biblioteca(int n) => <Song>[
      for (int i = 0; i < n; i++)
        Song(
          id: 's$i',
          path: '/musica/$i.mp3',
          title: 'Canción $i',
          artist: 'Artista',
          album: '',
          year: 0,
          genre: '',
          durationMs: 180000,
        ),
    ];

List<String> _ids(List<Song> canciones) => canciones.map((Song s) => s.id).toList();

void main() {
  test('Una pasada contiene cada canción exactamente una vez', () {
    final List<Song> todas = _biblioteca(50);
    final List<Song> cola = PlayerService.barajarCola(todas, <String>{}, Random(1));
    expect(cola.length, 50);
    expect(_ids(cola).toSet().length, 50);
    expect(_ids(cola).toSet(), _ids(todas).toSet());
  });

  test('La canción elegida va primera y no se repite después', () {
    final List<Song> todas = _biblioteca(30);
    final List<Song> cola = PlayerService.barajarCola(todas, <String>{}, Random(2), primera: 17);
    expect(cola.first.id, 's17');
    expect(_ids(cola).where((String id) => id == 's17').length, 1);
    expect(cola.length, 30);
  });

  test('Las que aún no han sonado van antes que las ya sonadas', () {
    final List<Song> todas = _biblioteca(20);
    final Set<String> sonadas = <String>{for (int i = 0; i < 8; i++) 's$i'};
    final List<Song> cola = PlayerService.barajarCola(todas, sonadas, Random(3));
    final List<String> primeras = _ids(cola).take(12).toList();
    expect(primeras.every((String id) => !sonadas.contains(id)), isTrue);
    expect(_ids(cola).skip(12).every(sonadas.contains), isTrue);
  });

  test('Si ya sonaron todas, empieza una pasada nueva', () {
    final List<Song> todas = _biblioteca(10);
    final Set<String> sonadas = _ids(todas).toSet();
    final List<Song> cola = PlayerService.barajarCola(todas, sonadas, Random(4));
    expect(sonadas, isEmpty);
    expect(_ids(cola).toSet().length, 10);
  });

  test('Escuchando la cola en orden (como hace el motor) no se repite nada en una pasada', () {
    final List<Song> todas = _biblioteca(40);
    final Set<String> sonadas = <String>{};
    final Random azar = Random(5);
    // Se pulsa "Aleatorio" varias veces en la misma sesión escuchando unas
    // cuantas cada vez: ninguna se repite hasta haber sonado las 40.
    final List<String> escuchadas = <String>[];
    while (escuchadas.length < 40) {
      final List<Song> cola = PlayerService.barajarCola(todas, sonadas, azar);
      for (final Song s in cola.take(7)) {
        if (escuchadas.length == 40) break;
        escuchadas.add(s.id);
        sonadas.add(s.id);
      }
    }
    expect(escuchadas.toSet().length, 40, reason: 'Ninguna canción se repitió antes de oírlas todas');
  });

  test('Dos barajados distintos dan órdenes distintos', () {
    final List<Song> todas = _biblioteca(50);
    final List<String> a = _ids(PlayerService.barajarCola(todas, <String>{}, Random(10)));
    final List<String> b = _ids(PlayerService.barajarCola(todas, <String>{}, Random(11)));
    expect(a, isNot(equals(b)));
  });
}

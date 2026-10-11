import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/song.dart';
import '../core/constants.dart';

/// Una pista tal y como la devuelve MediaStore (antes de convertirse en [Song]).
class ScannedTrack {
  const ScannedTrack({
    required this.mediaId,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumId,
    required this.year,
    required this.durationMs,
    required this.sizeBytes,
    required this.mimeType,
    required this.path,
    required this.uri,
  });

  final int mediaId;
  final String title;
  final String artist;
  final String album;
  final int albumId;
  final int year;
  final int durationMs;
  final int sizeBytes;
  final String? mimeType;

  /// Ruta real del archivo (puede ser null en Android 10+).
  final String? path;

  /// URI `content://` siempre disponible (se usa cuando no hay ruta).
  final String uri;

  /// Fuente reproducible: ruta de archivo o URI de contenido.
  String get source => (path != null && path!.isNotEmpty) ? path! : uri;

  bool get isPlayable => source.isNotEmpty;

  static ScannedTrack? fromMap(Map<dynamic, dynamic> map) {
    final int mediaId = (map['id'] as num?)?.toInt() ?? -1;
    if (mediaId <= 0) return null;
    return ScannedTrack(
      mediaId: mediaId,
      title: ((map['title'] as String?) ?? '').trim(),
      artist: ((map['artist'] as String?) ?? '').trim(),
      album: ((map['album'] as String?) ?? '').trim(),
      albumId: (map['albumId'] as num?)?.toInt() ?? -1,
      year: (map['year'] as num?)?.toInt() ?? 0,
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
      mimeType: map['mimeType'] as String?,
      path: map['path'] as String?,
      uri: (map['uri'] as String?) ?? '',
    );
  }

  /// Identificador estable en BotMp3 (independiente de cambios de ruta).
  String get songId => 'ms_$mediaId';

  Song toSong({String? coverPath}) {
    final String cleanTitle = title.isEmpty ? 'Sin título' : title;
    final String cleanArtist = (artist.isEmpty || artist == '<unknown>')
        ? 'Artista desconocido'
        : artist;
    return Song(
      id: songId,
      path: source,
      title: cleanTitle,
      artist: cleanArtist,
      album: album,
      year: year > 3000 ? 0 : year,
      genre: GenreCatalog.normalize(_guessGenre(album, cleanTitle)),
      durationMs: durationMs,
      coverPath: coverPath,
      fileSizeBytes: sizeBytes,
    );
  }

  static String? _guessGenre(String album, String title) {
    final String lower = '$album $title'.toLowerCase();
    for (final String genre in GenreCatalog.all) {
      if (lower.contains(genre.toLowerCase())) return genre;
    }
    return null;
  }
}

/// Puente Dart → Kotlin sobre MediaStore (escaneo automático de la biblioteca).
class MediaScanner {
  const MediaScanner._();

  static const MethodChannel _channel = MethodChannel('botmp3/media');

  /// Devuelve todas las pistas musicales del dispositivo.
  /// Nunca lanza: si el canal no está disponible devuelve una lista vacía.
  static Future<List<ScannedTrack>> queryAudio() async {
    try {
      final List<dynamic>? raw = await _channel.invokeMethod<List<dynamic>>('queryAudio');
      if (raw == null) return <ScannedTrack>[];
      final List<ScannedTrack> tracks = <ScannedTrack>[];
      for (final dynamic item in raw) {
        if (item is Map) {
          final ScannedTrack? track = ScannedTrack.fromMap(item);
          if (track != null && track.isPlayable) tracks.add(track);
        }
      }
      return tracks;
    } on MissingPluginException {
      debugPrint('MediaScanner no disponible (¿ejecutando fuera de Android?)');
      return <ScannedTrack>[];
    } on PlatformException catch (error) {
      debugPrint('Error al consultar MediaStore: ${error.message}');
      return <ScannedTrack>[];
    }
  }

  /// Extrae la carátula del álbum a un archivo local y devuelve su ruta.
  static Future<String?> albumArtPath(int albumId) async {
    if (albumId <= 0) return null;
    try {
      return await _channel.invokeMethod<String>('albumArt', <String, dynamic>{'albumId': albumId});
    } catch (error) {
      debugPrint('No se pudo extraer la carátula del álbum $albumId: $error');
      return null;
    }
  }

  /// Carátula del álbum de una pista concreta (id de MediaStore).
  /// Se usa en el editor para "usar la carátula original del álbum".
  static Future<String?> albumArtForTrack(String songId) async {
    final RegExpMatch? match = RegExp(r'^ms_(\d+)$').firstMatch(songId);
    if (match == null) return null;
    final int trackId = int.tryParse(match.group(1)!) ?? -1;
    if (trackId <= 0) return null;
    try {
      return await _channel.invokeMethod<String>(
        'albumArtForTrack',
        <String, dynamic>{'trackId': trackId},
      );
    } catch (error) {
      debugPrint('No se pudo extraer la carátula de la pista $trackId: $error');
      return null;
    }
  }
}

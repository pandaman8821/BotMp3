import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../core/constants.dart';
import '../core/formatters.dart';
import '../models/song.dart';
import 'storage_service.dart';

/// Metadatos leídos de las etiquetas del archivo (ID3/MP4/FLAC/OGG…).
class TrackTags {
  const TrackTags({
    this.title,
    this.artist,
    this.album,
    this.year,
    this.genre,
    this.durationMs,
    this.coverBytes,
    this.coverMimeType,
  });

  final String? title;
  final String? artist;
  final String? album;
  final int? year;
  final String? genre;
  final int? durationMs;
  final Uint8List? coverBytes;
  final String? coverMimeType;
}

/// Metadatos y importación de archivos a la biblioteca.
///
/// BotMp3 guarda los metadatos en su **propia biblioteca JSON** (título, artista,
/// álbum, año, género, duración y etiquetas), de modo que funciona con cualquier
/// formato y sin dependencias nativas.
///
/// La lectura/escritura de etiquetas dentro del archivo (ID3/MP4/FLAC/OGG) se
/// delega en métodos que hoy devuelven un valor neutro: para activarla basta con
/// volver a añadir el paquete `audiotags` al `pubspec.yaml` y restaurar las tres
/// comprobaciones marcadas con `PUNTO DE EXTENSIÓN`. Se mantiene así el mismo
/// contrato público para el resto de la app.
class MetadataService {
  MetadataService({StorageService? storage})
      : _storage = storage ?? StorageService.instance;

  final StorageService _storage;

  /// PUNTO DE EXTENSIÓN: lectura de etiquetas del archivo.
  /// Devuelve `null` cuando no hay lector de etiquetas disponible, y la app usa
  /// el nombre del archivo como datos mínimos (nunca falla).
  Future<TrackTags?> readTags(String path) async {
    debugPrint('Etiquetas del archivo no disponibles para $path (se usará el nombre del archivo)');
    return null;
  }

  /// PUNTO DE EXTENSIÓN: escritura de etiquetas dentro del archivo.
  Future<bool> writeTags(Song song) async {
    debugPrint('La escritura de etiquetas en el archivo no está activada; '
        'los metadatos se guardan en la biblioteca local de BotMp3.');
    return false;
  }

  /// PUNTO DE EXTENSIÓN: incrustar la carátula dentro del archivo.
  Future<bool> writeCover(Song song, Uint8List coverBytes, {bool isPng = false}) async {
    debugPrint('La carátula se guarda en la carpeta de carátulas de BotMp3 '
        '(este formato no admite escritura de etiquetas sin la extensión nativa).');
    return false;
  }

  /// Duración del audio.
  ///
  /// **Importante:** no se crea un `AudioPlayer` temporal aquí.
  /// `just_audio_background` solo admite UN reproductor por app; un segundo
  /// reproductor (aunque sea temporal) pasa a ser el que controla la sesión
  /// multimedia y los botones de la pantalla de bloqueo dejan de responder.
  /// La duración real la informa el propio reproductor al empezar a sonar.
  Future<int> readDurationMs(String path) async => 0;

  /// Construye una [Song] a partir de un archivo: etiquetas → nombre de archivo.
  Future<Song> buildSongFromPath(
    String path, {
    String? forcedTitle,
    String? forcedArtist,
    bool extractCover = true,
  }) async {
    final File file = File(path);
    final String fileName = path.split(RegExp(r'[\\/]')).last;
    final TrackTags? tags = await readTags(path);
    final (String guessedArtist, String guessedTitle) =
        Formatters.guessArtistAndTitle(fileName);

    int durationMs = tags?.durationMs ?? 0;
    if (durationMs <= 0) {
      durationMs = await readDurationMs(path);
    }

    String? coverPath;
    if (extractCover && tags?.coverBytes != null && tags!.coverBytes!.isNotEmpty) {
      try {
        coverPath = await _storage.saveCoverBytes(
          fileName,
          tags.coverBytes!,
          png: (tags.coverMimeType ?? '').contains('png'),
        );
      } catch (error) {
        debugPrint('No se pudo guardar la carátula embebida: $error');
        coverPath = null;
      }
    }

    int size = 0;
    try {
      if (file.existsSync()) size = await file.length();
    } catch (_) {}

    return Song(
      id: _idFor(path),
      path: path,
      title: forcedTitle ?? tags?.title ?? guessedTitle,
      artist: forcedArtist ?? tags?.artist ?? guessedArtist,
      album: tags?.album ?? '',
      year: tags?.year ?? 0,
      genre: GenreCatalog.normalize(tags?.genre ?? _guessGenreFromFolder(path)),
      durationMs: durationMs,
      coverPath: coverPath,
      fileSizeBytes: size,
    );
  }

  /// Identificador estable derivado de la ruta (evita duplicados al reimportar).
  static String _idFor(String path) =>
      '${path.hashCode.toRadixString(16)}_${path.length}';

  static String? _clean(String? value) {
    final String? trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    const List<String> junk = <String>['unknown', 'desconocido', 'various artists'];
    if (junk.contains(trimmed.toLowerCase())) return null;
    return trimmed;
  }

  /// Deduce el género por el nombre de alguna carpeta de la ruta.
  static String? _guessGenreFromFolder(String path) {
    final String lower = path.toLowerCase();
    for (final String genre in GenreCatalog.all) {
      if (lower.contains(genre.toLowerCase())) return genre;
    }
    return null;
  }

  /// Importa una lista de rutas devolviendo las canciones construidas.
  Future<List<Song>> importPaths(
    List<String> paths, {
    void Function(int done, int total, String current)? onProgress,
  }) async {
    final List<Song> result = <Song>[];
    int index = 0;
    for (final String path in paths) {
      index++;
      try {
        if (!AudioFormats.isSupported(path)) {
          onProgress?.call(index, paths.length, path);
          continue;
        }
        final Song song = await buildSongFromPath(path);
        result.add(song);
      } catch (error) {
        debugPrint('No se pudo importar $path: $error');
      }
      onProgress?.call(index, paths.length, path);
    }
    return result;
  }
}

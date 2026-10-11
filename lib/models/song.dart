import 'dart:convert';

import '../core/constants.dart';
import '../core/formatters.dart';

/// Canción de la biblioteca local.
///
/// Campos obligatorios (según especificación): título, artista, álbum, año,
/// género y duración. Además admite etiquetas (tags) libres para búsquedas
/// avanzadas y una carátula propia.
class Song {
  Song({
    required this.id,
    required this.path,
    required this.title,
    required this.artist,
    required this.album,
    required this.year,
    required this.genre,
    required this.durationMs,
    this.tags = const <String>[],
    this.coverPath,
    this.fileSizeBytes = 0,
    DateTime? addedAt,
    this.playCount = 0,
    this.lastPlayedAt,
    this.isFavorite = false,
  }) : addedAt = addedAt ?? DateTime.now();

  final String id;

  /// Ruta absoluta del archivo de audio (o ruta dentro del almacenamiento de la app).
  final String path;

  final String title;
  final String artist;
  final String album;

  /// Año de publicación (0 = desconocido).
  final int year;

  /// Género normalizado contra [GenreCatalog].
  final String genre;

  final int durationMs;

  /// Etiquetas extra para búsqueda avanzada ("verano", "fiesta", "bolivia"...).
  final List<String> tags;

  /// Ruta del archivo de imagen de carátula (PNG/JPG) editada o importada.
  final String? coverPath;

  final int fileSizeBytes;
  final DateTime addedAt;
  final int playCount;
  final DateTime? lastPlayedAt;
  final bool isFavorite;

  Duration get duration => Duration(milliseconds: durationMs);

  String get extension => AudioFormats.extensionOf(path);

  /// Blob normalizado usado por el índice de búsqueda.
  String get searchBlob => Formatters.normalize(
        <String>[
          title,
          artist,
          album,
          genre,
          year > 0 ? '$year' : '',
          tags.join(' '),
          path.split('/').last,
        ].join(' '),
      );

  /// Línea secundaria de la tarjeta: artista · álbum · año.
  String get subtitle {
    final List<String> parts = <String>[
      artist.isEmpty ? 'Artista desconocido' : artist,
      if (album.isNotEmpty) album,
      if (year > 0) '$year',
    ];
    return parts.join(' · ');
  }

  Song copyWith({
    String? path,
    String? title,
    String? artist,
    String? album,
    int? year,
    String? genre,
    int? durationMs,
    List<String>? tags,
    Object? coverPath = _unset,
    int? fileSizeBytes,
    DateTime? addedAt,
    int? playCount,
    DateTime? lastPlayedAt,
    bool? isFavorite,
  }) {
    return Song(
      id: id,
      path: path ?? this.path,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      durationMs: durationMs ?? this.durationMs,
      tags: tags ?? this.tags,
      coverPath: identical(coverPath, _unset) ? this.coverPath : coverPath as String?,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      addedAt: addedAt ?? this.addedAt,
      playCount: playCount ?? this.playCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'path': path,
        'title': title,
        'artist': artist,
        'album': album,
        'year': year,
        'genre': genre,
        'durationMs': durationMs,
        'tags': tags,
        'coverPath': coverPath,
        'fileSizeBytes': fileSizeBytes,
        'addedAt': addedAt.toIso8601String(),
        'playCount': playCount,
        'lastPlayedAt': lastPlayedAt?.toIso8601String(),
        'isFavorite': isFavorite,
      };

  static Song fromJson(Map<String, dynamic> json) {
    return Song(
      id: (json['id'] ?? '').toString(),
      path: (json['path'] ?? '').toString(),
      title: (json['title'] ?? 'Sin título').toString(),
      artist: (json['artist'] ?? 'Artista desconocido').toString(),
      album: (json['album'] ?? '').toString(),
      year: _asInt(json['year']),
      genre: GenreCatalog.normalize(json['genre']?.toString()),
      durationMs: _asInt(json['durationMs']),
      tags: (json['tags'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic tag) => tag.toString())
          .toList(),
      coverPath: json['coverPath']?.toString(),
      fileSizeBytes: _asInt(json['fileSizeBytes']),
      addedAt: _asDate(json['addedAt']),
      playCount: _asInt(json['playCount']),
      lastPlayedAt: json['lastPlayedAt'] == null ? null : _asDate(json['lastPlayedAt']),
      isFavorite: json['isFavorite'] == true,
    );
  }

  /// Payload que se envía al modelo de IA (sin rutas locales).
  Map<String, dynamic> toAiJson() => <String, dynamic>{
        'titulo': title,
        'artista': artist,
        'album': album,
        if (year > 0) 'anio': year,
        'genero': genre,
        'duracion': Formatters.duration(duration),
        if (tags.isNotEmpty) 'tags': tags,
      };

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _asDate(Object? value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  @override
  String toString() => jsonEncode(toAiJson());

  @override
  bool operator ==(Object other) => other is Song && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Valor centinela para distinguir `null` de "no cambiar" en [Song.copyWith].
const Object _unset = Object();

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/formatters.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'metadata_service.dart';
import 'storage_service.dart';

/// Núcleo de la biblioteca: canciones, listas, búsqueda avanzada y
/// exportación/importación de listas en JSON.
///
/// Todo se persiste localmente en un único archivo JSON (modo offline total).
class LibraryService {
  LibraryService({StorageService? storage, MetadataService? metadata})
      : _storage = storage ?? StorageService.instance,
        _metadata = metadata ?? MetadataService();

  final StorageService _storage;
  final MetadataService _metadata;

  final List<Song> _songs = <Song>[];
  final List<Playlist> _playlists = <Playlist>[];
  final Map<String, String> _searchIndex = <String, String>{};

  List<Song> get songs => List<Song>.unmodifiable(_songs);
  List<Playlist> get playlists => List<Playlist>.unmodifiable(_playlists);

  int get songCount => _songs.length;

  // ------------------------------------------------------------------ carga

  Future<void> load() async {
    final Map<String, dynamic>? data = await _storage.readJsonMap(StorageKeys.library);
    _songs.clear();
    _playlists.clear();
    _searchIndex.clear();
    if (data != null) {
      final List<dynamic> rawSongs = data['songs'] as List<dynamic>? ?? <dynamic>[];
      for (final dynamic item in rawSongs) {
        if (item is Map<String, dynamic>) {
          final Song song = Song.fromJson(item);
          _songs.add(song);
          _searchIndex[song.id] = song.searchBlob;
        }
      }
      final List<dynamic> rawPlaylists = data['playlists'] as List<dynamic>? ?? <dynamic>[];
      for (final dynamic item in rawPlaylists) {
        if (item is Map<String, dynamic>) {
          _playlists.add(Playlist.fromJson(item));
        }
      }
    }
  }

  Future<void> _persist() async {
    await _storage.writeJson(StorageKeys.library, <String, dynamic>{
      'version': 1,
      'updatedAt': DateTime.now().toIso8601String(),
      'songs': _songs.map((Song song) => song.toJson()).toList(),
      'playlists': _playlists.map((Playlist playlist) => playlist.toJson()).toList(),
    });
  }

  // ------------------------------------------------------------------ canciones

  Song? songById(String id) {
    for (final Song song in _songs) {
      if (song.id == id) return song;
    }
    return null;
  }

  /// Importa archivos y añade los nuevos (ignora duplicados por ruta).
  Future<List<Song>> importPaths(
    List<String> paths, {
    void Function(int done, int total, String current)? onProgress,
  }) async {
    final List<Song> imported = await _metadata.importPaths(paths, onProgress: onProgress);
    final Set<String> existingPaths = _songs.map((Song s) => s.path).toSet();
    final List<Song> added = <Song>[];
    for (final Song song in imported) {
      if (existingPaths.contains(song.path)) continue;
      _songs.add(song);
      _searchIndex[song.id] = song.searchBlob;
      added.add(song);
    }
    if (added.isNotEmpty) await _persist();
    return added;
  }

  /// Cambia la ruta de varias canciones a la vez (una sola escritura).
  Future<void> updatePaths(Map<String, String> pathsBySongId) async {
    if (pathsBySongId.isEmpty) return;
    bool changed = false;
    for (final MapEntry<String, String> entry in pathsBySongId.entries) {
      final int index = _songs.indexWhere((Song song) => song.id == entry.key);
      if (index < 0) continue;
      _songs[index] = _songs[index].copyWith(path: entry.value);
      changed = true;
    }
    if (changed) await _persist();
  }

  /// Importa en bloque las pistas detectadas en MediaStore.
  /// Devuelve solo las canciones realmente nuevas (sin duplicados).
  Future<List<Song>> importScannedTracks(List<Song> tracks) async {
    if (tracks.isEmpty) return <Song>[];
    final Set<String> knownIds = _songs.map((Song song) => song.id).toSet();
    final Set<String> knownPaths = _songs.map((Song song) => song.path).toSet();
    final List<Song> added = <Song>[];
    for (final Song song in tracks) {
      if (knownIds.contains(song.id) || knownPaths.contains(song.path)) continue;
      _songs.add(song);
      _searchIndex[song.id] = song.searchBlob;
      knownIds.add(song.id);
      knownPaths.add(song.path);
      added.add(song);
    }
    if (added.isNotEmpty) await _persist();
    return added;
  }

  /// Aplica varias carátulas de golpe (una sola escritura en disco).
  Future<void> setCoversBulk(Map<String, String> coversBySongId) async {
    if (coversBySongId.isEmpty) return;
    bool changed = false;
    for (final MapEntry<String, String> entry in coversBySongId.entries) {
      final int index = _songs.indexWhere((Song song) => song.id == entry.key);
      if (index < 0) continue;
      _songs[index] = _songs[index].copyWith(coverPath: entry.value);
      changed = true;
    }
    if (changed) await _persist();
  }

  Future<void> upsertSong(Song song) async {
    final int index = _songs.indexWhere((Song s) => s.id == song.id);
    if (index >= 0) {
      _songs[index] = song;
    } else {
      _songs.add(song);
    }
    _searchIndex[song.id] = song.searchBlob;
    await _persist();
    // Se intenta reflejar los metadatos en el archivo (si el formato lo permite).
    if (index >= 0) {
      await _metadata.writeTags(song);
    }
  }

  Future<void> deleteSong(String id) async {
    _songs.removeWhere((Song song) => song.id == id);
    _searchIndex.remove(id);
    for (int i = 0; i < _playlists.length; i++) {
      final Playlist playlist = _playlists[i];
      if (playlist.songIds.contains(id)) {
        _playlists[i] = playlist.copyWith(
          songIds: playlist.songIds.where((String songId) => songId != id).toList(),
        );
      }
    }
    await _persist();
  }

  Future<void> toggleFavorite(String id) async {
    final Song? song = songById(id);
    if (song == null) return;
    await upsertSong(song.copyWith(isFavorite: !song.isFavorite));
  }

  /// Historial de reproducciones (para el ranking por periodo).
  final List<Map<String, dynamic>> _playLog = <Map<String, dynamic>>[];
  bool _historialCargado = false;

  /// Registra una reproducción (para estadísticas, ranking y recomendaciones).
  Future<void> registerPlay(String id) async {
    final Song? song = songById(id);
    if (song == null) return;
    final int index = _songs.indexWhere((Song s) => s.id == id);
    if (index < 0) return;
    final DateTime ahora = DateTime.now();
    _songs[index] = song.copyWith(
      playCount: song.playCount + 1,
      lastPlayedAt: ahora,
    );
    _playLog.add(<String, dynamic>{'id': id, 'at': ahora.toIso8601String()});
    // Se conservan las últimas 3000 reproducciones: suficiente para el ranking.
    if (_playLog.length > 3000) {
      _playLog.removeRange(0, _playLog.length - 3000);
    }
    await _persist();
    unawaited(_persistirHistorial());
  }

  Future<void> _persistirHistorial() async {
    try {
      await StorageService.instance.writeJson(StorageKeys.playLogFile, _playLog);
    } catch (error) {
      debugPrint('No se pudo guardar el historial de reproducciones: $error');
    }
  }

  /// Carga el historial desde disco (lo llama el proveedor al iniciar).
  Future<void> cargarHistorial() async {
    if (_historialCargado) return;
    _historialCargado = true;
    try {
      final List<dynamic>? datos =
          await StorageService.instance.readJsonList(StorageKeys.playLogFile);
      if (datos == null) return;
      _playLog
        ..clear()
        ..addAll(datos.whereType<Map<String, dynamic>>());
    } catch (error) {
      debugPrint('No se pudo leer el historial de reproducciones: $error');
    }
  }

  /// Reproducciones por canción desde una fecha (null = todo el historial).
  /// Si aún no hay historial, se usa el contador acumulado de cada canción.
  Map<String, int> playsSince(DateTime? from) {
    final Map<String, int> conteo = <String, int>{};
    if (_playLog.isEmpty) {
      if (from != null) return conteo;
      for (final Song song in _songs) {
        if (song.playCount > 0) conteo[song.id] = song.playCount;
      }
      return conteo;
    }
    for (final Map<String, dynamic> entrada in _playLog) {
      final String? id = entrada['id']?.toString();
      if (id == null) continue;
      if (from != null) {
        final DateTime? at = DateTime.tryParse(entrada['at']?.toString() ?? '');
        if (at == null || at.isBefore(from)) continue;
      }
      conteo[id] = (conteo[id] ?? 0) + 1;
    }
    return conteo;
  }

  /// Borra el historial y reinicia los contadores de reproducciones.
  Future<void> resetPlayStats() async {
    for (int i = 0; i < _songs.length; i++) {
      _songs[i] = _songs[i].copyWith(playCount: 0, lastPlayedAt: null);
    }
    _playLog.clear();
    _historialCargado = true;
    await _persist();
    await _persistirHistorial();
  }

  /// Canciones ordenadas por número de reproducciones.
  List<Song> topCanciones({DateTime? from, int limit = 100}) {
    final Map<String, int> conteo = playsSince(from);
    final List<Song> ordenadas = _songs.toList()
      ..sort((Song a, Song b) {
        final int ca = conteo[a.id] ?? 0;
        final int cb = conteo[b.id] ?? 0;
        if (ca != cb) return cb.compareTo(ca);
        return (b.lastPlayedAt ?? DateTime(0)).compareTo(a.lastPlayedAt ?? DateTime(0));
      });
    return ordenadas
        .where((Song song) => (conteo[song.id] ?? 0) > 0 || song.playCount > 0)
        .take(limit)
        .toList();
  }

  /// Agrupa las reproducciones por un campo de texto (artista, álbum, género).
  List<MapEntry<String, int>> _topPor(
    String Function(Song song) clave, {
    DateTime? from,
  }) {
    final bool hayHistorial = _playLog.isNotEmpty;
    final Map<String, int> conteo = playsSince(from);
    final Map<String, int> total = <String, int>{};
    for (final Song song in _songs) {
      final String k = clave(song).trim();
      if (k.isEmpty || k == 'Artista desconocido') continue;
      final int reproducciones =
          hayHistorial ? (conteo[song.id] ?? 0) : song.playCount;
      if (reproducciones <= 0) continue;
      total[k] = (total[k] ?? 0) + reproducciones;
    }
    final List<MapEntry<String, int>> lista = total.entries.toList()
      ..sort(
        (MapEntry<String, int> a, MapEntry<String, int> b) =>
            b.value.compareTo(a.value),
      );
    return lista.take(50).toList();
  }

  List<MapEntry<String, int>> topArtistas({DateTime? from}) =>
      _topPor((Song song) => song.artist, from: from);

  List<MapEntry<String, int>> topAlbumes({DateTime? from}) =>
      _topPor((Song song) => song.album, from: from);

  List<MapEntry<String, int>> topGeneros({DateTime? from}) =>
      _topPor((Song song) => song.genre, from: from);

  /// Aplica la carátula editada a una canción.
  Future<void> setCover(String songId, String coverPath, {bool alsoWriteToFile = true}) async {
    final Song? song = songById(songId);
    if (song == null) return;
    final int index = _songs.indexWhere((Song s) => s.id == songId);
    if (index < 0) return;

    final Song updated = song.copyWith(coverPath: coverPath);
    _songs[index] = updated;
    await _persist();

    if (!alsoWriteToFile) return;
    try {
      final Uint8List? bytes = await _readBytes(coverPath);
      if (bytes != null) {
        await _metadata.writeCover(
          updated,
          bytes,
          isPng: coverPath.toLowerCase().endsWith('.png'),
        );
      }
    } catch (error) {
      debugPrint('No se pudo incrustar la carátula en el archivo: $error');
    }
  }

  Future<Uint8List?> _readBytes(String path) async {
    try {
      final File file = File(path);
      if (!file.existsSync()) return null;
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------------ listas

  Playlist? playlistById(String id) {
    for (final Playlist playlist in _playlists) {
      if (playlist.id == id) return playlist;
    }
    return null;
  }

  Future<Playlist> createPlaylist({
    required String name,
    String description = '',
    List<String> songIds = const <String>[],
    bool isAiGenerated = false,
    String? aiPrompt,
  }) async {
    final Playlist playlist = Playlist(
      id: 'pl_${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'Lista sin nombre' : name.trim(),
      description: description.trim(),
      songIds: List<String>.from(songIds),
      isAiGenerated: isAiGenerated,
      aiPrompt: aiPrompt,
    );
    _playlists.add(playlist);
    await _persist();
    return playlist;
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    final int index = _playlists.indexWhere((Playlist p) => p.id == playlist.id);
    if (index < 0) return;
    _playlists[index] = playlist.copyWith(updatedAt: DateTime.now());
    await _persist();
  }

  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((Playlist playlist) => playlist.id == id);
    await _persist();
  }

  Future<void> addSongsToPlaylist(String playlistId, List<String> songIds) async {
    final Playlist? playlist = playlistById(playlistId);
    if (playlist == null) return;
    final List<String> merged = List<String>.from(playlist.songIds);
    for (final String id in songIds) {
      if (!merged.contains(id)) merged.add(id);
    }
    await updatePlaylist(playlist.copyWith(songIds: merged));
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final Playlist? playlist = playlistById(playlistId);
    if (playlist == null) return;
    await updatePlaylist(
      playlist.copyWith(
        songIds: playlist.songIds.where((String id) => id != songId).toList(),
      ),
    );
  }

  /// Reordena una canción dentro de la lista (drag & drop).
  Future<void> moveSongInPlaylist(String playlistId, int from, int to) async {
    final Playlist? playlist = playlistById(playlistId);
    if (playlist == null) return;
    final List<String> ids = List<String>.from(playlist.songIds);
    if (from < 0 || from >= ids.length) return;
    final String moved = ids.removeAt(from);
    ids.insert(to.clamp(0, ids.length), moved);
    await updatePlaylist(playlist.copyWith(songIds: ids));
  }

  List<Song> songsOf(Playlist playlist) {
    final List<Song> result = <Song>[];
    for (final String id in playlist.songIds) {
      final Song? song = songById(id);
      if (song != null) result.add(song);
    }
    return result;
  }

  // ------------------------------------------------------------------ búsqueda

  /// Búsqueda global por título, artista, álbum, género, año o tags, con
  /// filtros avanzados y puntuación de relevancia.
  List<Song> search(
    String query, {
    String? genre,
    String? artist,
    int? yearFrom,
    int? yearTo,
    List<String> tags = const <String>[],
    bool favoritesOnly = false,
    int limit = 200,
  }) {
    final String needle = Formatters.normalize(query);
    final List<String> tagNeedles =
        tags.map((String tag) => Formatters.normalize(tag)).where((String t) => t.isNotEmpty).toList();

    final List<(Song, double)> scored = <(Song, double)>[];

    for (final Song song in _songs) {
      if (favoritesOnly && !song.isFavorite) continue;
      if (genre != null && genre.isNotEmpty && song.genre != genre) continue;
      if (artist != null && artist.isNotEmpty) {
        if (Formatters.similarity(song.artist, artist) < 0.6) continue;
      }
      if (yearFrom != null && (song.year == 0 || song.year < yearFrom)) continue;
      if (yearTo != null && (song.year == 0 || song.year > yearTo)) continue;
      if (tagNeedles.isNotEmpty) {
        final List<String> normalizedTags =
            song.tags.map(Formatters.normalize).toList();
        final bool hasAll = tagNeedles.every(
          (String tag) => normalizedTags.any((String value) => value.contains(tag)),
        );
        if (!hasAll) continue;
      }

      if (needle.isEmpty) {
        scored.add((song, song.isFavorite ? 1.0 : 0.5));
        continue;
      }

      final String blob = _searchIndex[song.id] ?? song.searchBlob;
      double score = 0;
      if (blob.contains(needle)) score += 1.0;
      score += Formatters.similarity(song.title, query) * 1.2;
      score += Formatters.similarity(song.artist, query) * 0.9;
      if (song.album.isNotEmpty) score += Formatters.similarity(song.album, query) * 0.4;
      final bool yearMatch = song.year > 0 && needle.contains(song.year.toString());
      if (yearMatch) score += 0.6;
      if (song.isFavorite) score += 0.15;
      score += (song.playCount.clamp(0, 10)) * 0.01;

      if (score > 0.35) scored.add((song, score));
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.take(limit).map(((Song, double) entry) => entry.$1).toList();
  }

  /// Todos los artistas distintos ordenados alfabéticamente.
  List<String> get artists {
    final Set<String> values = _songs
        .map((Song song) => song.artist)
        .where((String artist) => artist.trim().isNotEmpty)
        .toSet();
    final List<String> sorted = values.toList()..sort();
    return sorted;
  }

  /// Años disponibles en la biblioteca (descendente).
  List<int> get years {
    final Set<int> values = _songs.map((Song song) => song.year).where((int y) => y > 0).toSet();
    final List<int> sorted = values.toList()..sort((int a, int b) => b.compareTo(a));
    return sorted;
  }

  /// Todas las etiquetas usadas (para el buscador avanzado).
  List<String> get tags {
    final Set<String> values = <String>{};
    for (final Song song in _songs) {
      values.addAll(song.tags);
    }
    final List<String> sorted = values.toList()..sort();
    return sorted;
  }

  /// Resumen de la biblioteca que se envía a la IA como contexto.
  List<Map<String, dynamic>> aiCatalog({int limit = 120}) {
    final List<Song> ordered = List<Song>.from(_songs)
      ..sort((Song a, Song b) => b.playCount.compareTo(a.playCount));
    return ordered
        .take(limit)
        .map((Song song) => song.toAiJson())
        .toList();
  }

  // --------------------------------------------------- exportar / importar

  /// Exporta TODA la biblioteca (canciones + listas) como JSON de respaldo.
  String exportLibraryJson() => jsonEncode(<String, dynamic>{
        'format': 'botmp3.library',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'songs': _songs.map((Song song) => song.toJson()).toList(),
        'playlists': _playlists.map((Playlist playlist) => playlist.toJson()).toList(),
      });

  /// Importa un respaldo de biblioteca y devuelve cuántas canciones nuevas entraron.
  Future<int> importLibraryJson(String jsonText) async {
    try {
      final dynamic decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) return 0;
      if (decoded['format'] != 'botmp3.library') return 0;

      int added = 0;
      final List<dynamic> rawSongs = decoded['songs'] as List<dynamic>? ?? <dynamic>[];
      for (final dynamic item in rawSongs) {
        if (item is! Map<String, dynamic>) continue;
        final Song song = Song.fromJson(item);
        if (_songs.every((Song existing) => existing.path != song.path)) {
          _songs.add(song);
          _searchIndex[song.id] = song.searchBlob;
          added++;
        }
      }

      final List<dynamic> rawPlaylists = decoded['playlists'] as List<dynamic>? ?? <dynamic>[];
      for (final dynamic item in rawPlaylists) {
        if (item is! Map<String, dynamic>) continue;
        final Playlist playlist = Playlist.fromJson(item);
        if (_playlists.every((Playlist existing) => existing.id != playlist.id)) {
          _playlists.add(playlist);
        }
      }

      await _persist();
      return added;
    } catch (error) {
      debugPrint('Respaldo inválido: $error');
      return 0;
    }
  }

  /// Exporta la lista a JSON portátil (incluye los datos de cada canción).
  String exportPlaylist(Playlist playlist) {
    final Map<String, dynamic> payload = playlist.toExportJson();
    payload['songsDetail'] = songsOf(playlist).map((Song s) => s.toAiJson()).toList();
    payload['songsLocalPath'] = songsOf(playlist).map((Song s) => s.path).toList();
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Importa una lista desde JSON. Si [matchWithLibrary] es true, las canciones
  /// que ya existen en la biblioteca se enlazan automáticamente por título/artista.
  Future<Playlist?> importPlaylist(
    String jsonText, {
    bool matchWithLibrary = true,
  }) async {
    try {
      final dynamic decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) return null;

      final String name = (decoded['name'] ?? 'Lista importada').toString();
      final String description = (decoded['description'] ?? '').toString();
      final List<dynamic> paths = decoded['songsLocalPath'] as List<dynamic>? ?? <dynamic>[];
      final List<dynamic> details = decoded['songsDetail'] as List<dynamic>? ?? <dynamic>[];
      final List<dynamic> ids = decoded['songs'] as List<dynamic>? ?? <dynamic>[];

      final List<String> resolvedIds = <String>[];

      // 1) Por id local.
      for (final dynamic id in ids) {
        final String value = id.toString();
        if (songById(value) != null) resolvedIds.add(value);
      }

      // 2) Por ruta de archivo.
      for (final dynamic pathValue in paths) {
        final String path = pathValue.toString();
        for (final Song song in _songs) {
          if (song.path == path && !resolvedIds.contains(song.id)) {
            resolvedIds.add(song.id);
            break;
          }
        }
      }

      // 3) Por título + artista (con similitud).
      if (matchWithLibrary && resolvedIds.length < details.length) {
        for (final dynamic entry in details) {
          if (entry is! Map<String, dynamic>) continue;
          final String title = (entry['titulo'] ?? entry['title'] ?? '').toString();
          final String artist = (entry['artista'] ?? entry['artist'] ?? '').toString();
          Song? best;
          double bestScore = 0;
          for (final Song song in _songs) {
            final double score =
                Formatters.similarity(song.title, title) * 0.65 +
                    Formatters.similarity(song.artist, artist) * 0.35;
            if (score > bestScore) {
              bestScore = score;
              best = song;
            }
          }
          if (best != null && bestScore >= 0.72 && !resolvedIds.contains(best.id)) {
            resolvedIds.add(best.id);
          }
        }
      }

      return createPlaylist(
        name: name,
        description: description,
        songIds: resolvedIds,
        isAiGenerated: decoded['isAiGenerated'] == true,
        aiPrompt: decoded['aiPrompt']?.toString(),
      );
    } catch (error) {
      debugPrint('JSON de lista inválido: $error');
      return null;
    }
  }
}

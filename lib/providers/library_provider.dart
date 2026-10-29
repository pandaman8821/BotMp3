import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/ai/ai_bridge.dart';
import '../core/formatters.dart';
import '../core/text_utils.dart';
import '../services/library_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../services/media_scanner.dart';

/// Estado de la biblioteca: canciones, listas, filtros y búsqueda global.
class LibraryProvider extends ChangeNotifier {
  LibraryProvider({LibraryService? service}) : _service = service ?? LibraryService() {
    AiBridge.library = this;
  }

  final LibraryService _service;

  bool _loading = true;
  String? _importMessage;
  double _importProgress = 0;
  bool _scanning = false;
  String? _scanMessage;

  // Filtros de la búsqueda avanzada.
  String _query = '';
  String? _genreFilter;
  String? _artistFilter;
  int? _yearFrom;
  int? _yearTo;
  final Set<String> _tagFilters = <String>{};
  bool _favoritesOnly = false;

  LibraryService get service => _service;
  List<Song> get songs => _service.songs;
  List<Playlist> get playlists => _service.playlists;
  bool get isLoading => _loading;
  String? get importMessage => _importMessage;
  double get importProgress => _importProgress;
  bool get isScanning => _scanning;
  String? get scanMessage => _scanMessage;

  String get query => _query;
  String? get genreFilter => _genreFilter;
  String? get artistFilter => _artistFilter;
  int? get yearFrom => _yearFrom;
  int? get yearTo => _yearTo;
  Set<String> get tagFilters => _tagFilters;
  bool get favoritesOnly => _favoritesOnly;

  bool get hasActiveFilters =>
      (_genreFilter != null && _genreFilter!.isNotEmpty) ||
      (_artistFilter != null && _artistFilter!.isNotEmpty) ||
      _yearFrom != null ||
      _yearTo != null ||
      _tagFilters.isNotEmpty ||
      _favoritesOnly;

  // ------------------------------------------------------------------ ciclo

  Future<void>? _loadFuture;

  Future<void> init() => _loadFuture ??= _load();

  Future<void> _load() async {
    await _service.load();
    // Historial de reproducciones para el ranking por periodo.
    await _service.cargarHistorial();
    _loading = false;
    notifyListeners();
  }

  // ------------------------------------------------------- almacenamiento

  /// Bytes que ocupa la caché de la app.
  Future<int> cacheBytes() => StorageService.instance.cacheSize();

  /// Libera espacio sin perder nada:
  ///  1. mueve a almacenamiento permanente las canciones guardadas en la caché;
  ///  2. borra la caché regenerable (carátulas temporales, restos del selector).
  /// Devuelve los bytes liberados.
  Future<int> freeSpace() async {
    if (_scanning) return 0;
    _scanning = true;
    _scanMessage = 'Liberando espacio…';
    notifyListeners();
    try {
      await init();
      final StorageService storage = StorageService.instance;
      final String cacheRoot = (await storage.cacheRoot()).path;
      final String importedRoot = (await storage.importedDirectory()).path;

      // Índice de la música real del dispositivo (por título+artista y por archivo).
      final List<ScannedTrack> enDispositivo = await MediaScanner.queryAudio();
      final Map<String, List<ScannedTrack>> porCancion = <String, List<ScannedTrack>>{};
      final Map<String, ScannedTrack> porArchivo = <String, ScannedTrack>{};
      for (final ScannedTrack track in enDispositivo) {
        porCancion
            .putIfAbsent(_claveDispositivo(track.title, track.artist), () => <ScannedTrack>[])
            .add(track);
        if (track.path != null && track.path!.isNotEmpty) {
          porArchivo[_nombreArchivo(track.path!)] = track;
        }
      }

      final Map<String, String> reapuntadas = <String, String>{};
      int liberado = 0;
      int recuperadas = 0;
      int movidas = 0;

      for (final Song song in List<Song>.from(_service.songs)) {
        final bool enCache = song.path.startsWith(cacheRoot);
        final bool enImportadas = song.path.startsWith(importedRoot);
        if (!enCache && !enImportadas) continue;

        final File file = File(song.path);
        if (!file.existsSync()) continue;

        // 1) Si la canción también está en la música del dispositivo, se usa el
        //    archivo ORIGINAL y se borra nuestra copia (aquí está el ahorro real).
        final ScannedTrack? original = _buscarEnDispositivo(song, porCancion, porArchivo);
        if (original != null) {
          reapuntadas[song.id] = original.source;
          try {
            liberado += await file.length();
            recuperadas++;
            await file.delete();
          } catch (_) {}
          continue;
        }

        // 2) Si no está en el dispositivo, al menos sale de la caché.
        if (enCache) {
          final String estable = await storage
              .moveImportedFile(song.path, file.uri.pathSegments.last);
          if (estable != song.path) {
            reapuntadas[song.id] = estable;
            movidas++;
          }
        }
      }

      if (reapuntadas.isNotEmpty) await _service.updatePaths(reapuntadas);

      // 3) Caché regenerable (nunca se toca lo que está en uso) + carátulas huérfanas.
      final Set<String> enUso = _service.songs.map((Song song) => song.path).toSet();
      liberado += await storage.clearRegenerableCache(protectedPaths: enUso);
      liberado += await _purgeOrphanCovers();

      _scanMessage = liberado > 0
          ? 'Liberados ${Formatters.bytes(liberado)}'
              '${recuperadas > 0 ? ' · $recuperadas copias reemplazadas por el original' : ''}'
          : 'No había nada que liberar';
      return liberado;
    } catch (error) {
      debugPrint('No se pudo liberar espacio: $error');
      _scanMessage = 'No se pudo liberar espacio';
      return 0;
    } finally {
      _scanning = false;
      notifyListeners();
    }
  }

  /// Clave para reconocer la misma canción entre la biblioteca y el dispositivo.
  static String _claveDispositivo(String title, String artist) =>
      '${title.toLowerCase().trim()}|${artist.toLowerCase().trim()}';

  static String _nombreArchivo(String path) {
    final String name = path.split(RegExp(r'[\\/]')).last;
    final int dot = name.lastIndexOf('.');
    return (dot > 0 ? name.substring(0, dot) : name).toLowerCase().trim();
  }

  /// Busca la canción original en la música del dispositivo.
  ScannedTrack? _buscarEnDispositivo(
    Song song,
    Map<String, List<ScannedTrack>> porCancion,
    Map<String, ScannedTrack> porArchivo,
  ) {
    final List<ScannedTrack>? candidatos =
        porCancion[_claveDispositivo(song.title, song.artist)];
    if (candidatos != null && candidatos.isNotEmpty) {
      if (candidatos.length == 1 || song.durationMs <= 0) return candidatos.first;
      for (final ScannedTrack track in candidatos) {
        if ((track.durationMs - song.durationMs).abs() <= 3000) return track;
      }
      return candidatos.first;
    }
    // Respaldo: mismo nombre de archivo (habitual al importar con el selector).
    return porArchivo[_nombreArchivo(song.path)];
  }

  /// Borra las carátulas que ya no pertenecen a ninguna canción.
  Future<int> _purgeOrphanCovers() async {
    int freed = 0;
    try {
      final Directory covers = await StorageService.instance.coversDirectory();
      final Set<String> used = _service.songs
          .map((Song song) => song.coverPath)
          .whereType<String>()
          .toSet();
      for (final FileSystemEntity entity in covers.listSync()) {
        if (entity is! File || used.contains(entity.path)) continue;
        try {
          final int size = await entity.length();
          await entity.delete();
          freed += size;
        } catch (_) {}
      }
    } catch (_) {}
    return freed;
  }

  // ------------------------------------------------------------ escaneo

  /// Escanea la música del dispositivo (MediaStore) y añade automáticamente
  /// las canciones nuevas. Devuelve cuántas se añadieron.
  Future<int> autoScan({bool force = false}) async {
    if (_scanning) return 0;
    _scanning = true;
    _scanMessage = 'Buscando música en el dispositivo…';
    notifyListeners();
    try {
      await init();
      final bool incluirAudios =
          SettingsService.actual?.importMediaAudio ?? true;
      final List<ScannedTrack> tracks =
          await MediaScanner.queryAudio(includeNonMusic: incluirAudios);
      if (tracks.isEmpty) {
        _scanMessage = 'No se encontró música en el dispositivo';
        return 0;
      }
      final List<Song> found = tracks
          .map((ScannedTrack track) => track.toSong())
          .toList(growable: false);

      // No se duplican canciones que ya están en la biblioteca
      // (aunque apunten a una copia importada).
      final Set<String> conocidas = <String>{
        for (final Song song in _service.songs)
          _claveDispositivo(song.title, song.artist),
      };
      final List<Song> nuevas = found
          .where((Song song) =>
              !conocidas.contains(_claveDispositivo(song.title, song.artist)))
          .toList(growable: false);
      final List<Song> added = await _service.importScannedTracks(nuevas);
      _scanMessage = added.isEmpty
          ? 'Biblioteca al día (${found.length} pistas en el dispositivo)'
          : '${added.length} canciones nuevas de ${found.length}';
      if (added.isNotEmpty) {
        final Map<String, ScannedTrack> byId = <String, ScannedTrack>{
          for (final ScannedTrack track in tracks) track.songId: track,
        };
        unawaited(_fetchAlbumArt(added, byId));
      }
      return added.length;
    } catch (error) {
      debugPrint('Error al escanear la biblioteca: $error');
      _scanMessage = 'No se pudo escanear la biblioteca';
      return 0;
    } finally {
      _scanning = false;
      notifyListeners();
    }
  }

  /// Descarga en segundo plano las carátulas de los álbumes importados.
  Future<void> _fetchAlbumArt(List<Song> songs, Map<String, ScannedTrack> tracks) async {
    final Map<String, String> covers = <String, String>{};
    int processed = 0;
    for (final Song song in songs) {
      final ScannedTrack? track = tracks[song.id];
      if (track == null || track.albumId <= 0) continue;
      final String? path = await MediaScanner.albumArtPath(track.albumId);
      if (path != null) covers[song.id] = path;
      processed++;
      if (covers.length >= 20) {
        await _service.setCoversBulk(covers);
        covers.clear();
        notifyListeners();
      }
    }
    if (covers.isNotEmpty) await _service.setCoversBulk(covers);
    if (processed > 0) _scanMessage = 'Carátulas actualizadas ($processed canciones)';
    notifyListeners();
  }

  // ------------------------------------------------------------ consultas

  /// Resultado de aplicar la consulta y los filtros activos.
  List<Song> get visibleSongs {
    final List<Song> lista = _service.search(
      _query,
      genre: _genreFilter,
      artist: _artistFilter,
      yearFrom: _yearFrom,
      yearTo: _yearTo,
      tags: _tagFilters.toList(),
      favoritesOnly: _favoritesOnly,
    );
    // Los audios de apps y las notas de voz solo se muestran si el usuario
    // activa la opción (así también desaparecen los ya importados antes).
    if (SettingsService.actual?.importMediaAudio ?? true) return lista;
    return lista
        .where((Song song) => !pareceAudioDeApp(song))
        .toList(growable: false);
  }

  List<Song> songsOf(Playlist playlist) => _service.songsOf(playlist);

  Song? songById(String id) => _service.songById(id);

  List<String> get artists => _service.artists;
  List<int> get years => _service.years;
  List<String> get allTags => _service.tags;
  /// Lista por id (usada por la pantalla de detalle).
  Playlist? playlistById(String id) => _service.playlistById(id);


  /// Canciones más escuchadas (para la pantalla de inicio).
  List<Song> get mostPlayed {
    final List<Song> ordered = List<Song>.from(_service.songs)
      ..sort((Song a, Song b) => b.playCount.compareTo(a.playCount));
    return ordered.where((Song song) => song.playCount > 0).take(20).toList();
  }

  List<Song> get recentlyAdded {
    final List<Song> ordered = List<Song>.from(_service.songs)
      ..sort((Song a, Song b) => b.addedAt.compareTo(a.addedAt));
    return ordered.take(20).toList();
  }

  // ------------------------------------------------------------------ acciones

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setGenreFilter(String? genre) {
    _genreFilter = genre;
    notifyListeners();
  }

  void setArtistFilter(String? artist) {
    _artistFilter = artist;
    notifyListeners();
  }

  void setYearRange(int? from, int? to) {
    _yearFrom = from;
    _yearTo = to;
    notifyListeners();
  }

  void toggleTagFilter(String tag) {
    if (_tagFilters.contains(tag)) {
      _tagFilters.remove(tag);
    } else {
      _tagFilters.add(tag);
    }
    notifyListeners();
  }

  void toggleFavoritesOnly() {
    _favoritesOnly = !_favoritesOnly;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _genreFilter = null;
    _artistFilter = null;
    _yearFrom = null;
    _yearTo = null;
    _tagFilters.clear();
    _favoritesOnly = false;
    notifyListeners();
  }

  Future<int> importPaths(List<String> paths) async {
    _importProgress = 0;
    _importMessage = 'Importando…';
    notifyListeners();

    final List<Song> added = await _service.importPaths(
      paths,
      onProgress: (int done, int total, String current) {
        _importProgress = total == 0 ? 0 : done / total;
        _importMessage = 'Importando $done/$total…';
        notifyListeners();
      },
    );

    _importMessage = added.isEmpty
        ? 'No se añadió ninguna canción nueva'
        : '${added.length} canción(es) importada(s)';
    _importProgress = 0;
    notifyListeners();
    return added.length;
  }

  /// Rellena el género de las canciones que no lo tengan usando una heurística
  /// LOCAL (nombre del género en el título o el álbum). Sin IA, sin claves y sin
  /// conexión: funciona siempre. Devuelve cuántas se etiquetaron.
  Future<int> completarGeneros() async {
    int cambiadas = 0;
    for (final Song song in List<Song>.from(_service.songs)) {
      if (song.genre.trim().isNotEmpty) continue;
      final String pista = '${song.album} ${song.title}'.toLowerCase();
      String? genero;
      for (final String g in GenreCatalog.all) {
        if (pista.contains(g.toLowerCase())) {
          genero = g;
          break;
        }
      }
      if (genero == null) continue;
      await _service.upsertSong(song.copyWith(genre: genero));
      cambiadas++;
    }
    if (cambiadas > 0) notifyListeners();
    return cambiadas;
  }
  Future<void> saveSong(Song song) async {
    await _service.upsertSong(song);
    notifyListeners();
  }

  Future<void> deleteSong(String id) async {
    await _service.deleteSong(id);
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    await _service.toggleFavorite(id);
    notifyListeners();
  }

  /// Reinicia el ranking (contadores e historial).
  Future<void> resetPlayStats() async {
    await _service.resetPlayStats();
    notifyListeners();
  }

  /// Copia de seguridad interna (semanal, o forzada desde Ajustes).
  Future<bool> autoBackup({bool forzar = false}) async {
    final bool hecha = await _service.copiaAutomatica(forzar: forzar);
    notifyListeners();
    return hecha;
  }

  Future<DateTime?> ultimaCopia() => _service.ultimaCopia();

  Future<void> registerPlay(String id) async {
    await _service.registerPlay(id);
    notifyListeners();
  }

  Future<void> setCover(String songId, String coverPath) async {
    await _service.setCover(songId, coverPath);
    notifyListeners();
  }

  Future<Playlist> createPlaylist({
    required String name,
    String description = '',
    List<String> songIds = const <String>[],
    bool isAiGenerated = false,
    String? aiPrompt,
  }) async {
    final Playlist playlist = await _service.createPlaylist(
      name: name,
      description: description,
      songIds: songIds,
      isAiGenerated: isAiGenerated,
      aiPrompt: aiPrompt,
    );
    notifyListeners();
    return playlist;
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    await _service.updatePlaylist(playlist);
    notifyListeners();
  }

  Future<void> deletePlaylist(String id) async {
    await _service.deletePlaylist(id);
    notifyListeners();
  }

  Future<void> addSongsToPlaylist(String playlistId, List<String> songIds) async {
    await _service.addSongsToPlaylist(playlistId, songIds);
    notifyListeners();
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await _service.removeSongFromPlaylist(playlistId, songId);
    notifyListeners();
  }

  Future<void> moveSongInPlaylist(String playlistId, int from, int to) async {
    await _service.moveSongInPlaylist(playlistId, from, to);
    notifyListeners();
  }

  String exportPlaylist(Playlist playlist) => _service.exportPlaylist(playlist);

  /// Respaldo completo de la biblioteca (canciones + listas) en JSON.
  String exportLibraryJson() => _service.exportLibraryJson();

  /// Restaura un respaldo. Devuelve cuántas canciones nuevas se añadieron.
  Future<int> importLibraryJson(String json) async {
    final int added = await _service.importLibraryJson(json);
    notifyListeners();
    return added;
  }

  /// Borra toda la biblioteca local (los archivos de audio no se tocan).
  Future<void> clearLibrary() async {
    for (final Song song in List<Song>.from(_service.songs)) {
      await _service.deleteSong(song.id);
    }
    for (final Playlist playlist in List<Playlist>.from(_service.playlists)) {
      await _service.deletePlaylist(playlist.id);
    }
    notifyListeners();
  }

  Future<Playlist?> importPlaylistJson(String json) async {
    final Playlist? playlist = await _service.importPlaylist(json);
    notifyListeners();
    return playlist;
  }

  void clearImportMessage() {
    _importMessage = null;
    notifyListeners();
  }

  /// Etiqueta legible con el resumen de la biblioteca (para la pantalla IA).
  String get summaryLabel {
    final int total = _service.songs.length;
    final int genres = _service.songs.map((Song s) => s.genre).toSet().length;
    return '$total canciones · $genres géneros · ${_service.playlists.length} listas';
  }

  /// Países/idiomas no aplican: se deja el catálogo listo para la IA.
  List<Map<String, dynamic>> aiCatalog({int limit = 80}) => _service.aiCatalog(limit: limit);

  @override
  void dispose() {
    _importMessage = null;
    super.dispose();
  }
}

/// Utilidad para mantener un temporizador simple de "debounce" en búsquedas.
class Debouncer {
  Debouncer({this.milliseconds = 250});

  final int milliseconds;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() => _timer?.cancel();
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters.dart';
import '../core/text_utils.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import 'ranking_screen.dart';
import '../widgets/dialogs.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_tile.dart';
import 'car_mode_screen.dart';
import 'lyrics_screen.dart';

/// Pantalla principal: biblioteca local con orden, selección múltiple y filtros.
class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

enum _SortMode { recientes, titulo, artista, album, anio, duracion, reproducciones }

class _SongsScreenState extends State<SongsScreen> {
  _SortMode _sort = _SortMode.recientes;
  bool _selectionMode = false;
  final Set<String> _selected = <String>{};

  /// Opción del menú de orden, marcada si está activa.
  PopupMenuItem<_SortMode> _ordenItem(String texto, _SortMode modo) {
    final bool activo = _sort == modo;
    return CheckedPopupMenuItem<_SortMode>(
      value: modo,
      checked: activo,
      child: Text(
        texto,
        style: TextStyle(fontWeight: activo ? FontWeight.w700 : FontWeight.w400),
      ),
    );
  }

  List<Song> _sorted(List<Song> input) {
    final List<Song> songs = List<Song>.from(input);
    switch (_sort) {
      case _SortMode.recientes:
        songs.sort((Song a, Song b) {
          final int porFecha = b.addedAt.compareTo(a.addedAt);
          return porFecha != 0 ? porFecha : compararTextos(a.title, b.title);
        });
      case _SortMode.titulo:
        songs.sort((Song a, Song b) => compararTextos(a.title, b.title));
      case _SortMode.artista:
        songs.sort((Song a, Song b) {
          final int porArtista = compararTextos(a.artist, b.artist);
          return porArtista != 0 ? porArtista : compararTextos(a.title, b.title);
        });
      case _SortMode.album:
        songs.sort((Song a, Song b) {
          final int porAlbum = compararTextos(a.album, b.album);
          return porAlbum != 0 ? porAlbum : compararTextos(a.title, b.title);
        });
      case _SortMode.anio:
        songs.sort((Song a, Song b) {
          // Los años desconocidos (0) van al final, no al principio.
          final int ya = a.year <= 0 ? -1 : a.year;
          final int yb = b.year <= 0 ? -1 : b.year;
          if (ya != yb) return yb.compareTo(ya);
          return compararTextos(a.title, b.title);
        });
      case _SortMode.duracion:
        songs.sort((Song a, Song b) => b.durationMs.compareTo(a.durationMs));
      case _SortMode.reproducciones:
        songs.sort((Song a, Song b) {
          final int porReproducciones = b.playCount.compareTo(a.playCount);
          return porReproducciones != 0
              ? porReproducciones
              : compararTextos(a.title, b.title);
        });
    }
    return songs;
  }

  @override
  Widget build(BuildContext context) {
    final LibraryProvider library = context.watch<LibraryProvider>();
    final PlayerProvider player = context.watch<PlayerProvider>();
    final List<Song> songs = _sorted(library.visibleSongs);

    return Scaffold(
      appBar: AppBar(
        title: _selectionMode ? Text('${_selected.length} seleccionadas') : const Text('BotMp3'),
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _selectionMode = false;
                  _selected.clear();
                }),
              )
            : null,
        actions: _selectionMode
            ? <Widget>[
                IconButton(
                  tooltip: 'Añadir a lista',
                  icon: const Icon(Icons.playlist_add),
                  onPressed: () async {
                    final List<Song> chosen = songs
                        .where((Song song) => _selected.contains(song.id))
                        .toList();
                    await AppDialogs.addSongsToPlaylist(context, chosen);
                    if (mounted) {
                      setState(() {
                        _selectionMode = false;
                        _selected.clear();
                      });
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Reproducir selección',
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {
                    final List<Song> chosen =
                        songs.where((Song song) => _selected.contains(song.id)).toList();
                    if (chosen.isNotEmpty) player.setQueue(chosen);
                  },
                ),
              ]
            : <Widget>[
                IconButton(
                  tooltip: 'Ranking de lo más escuchado',
                  icon: const Icon(Icons.leaderboard_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const RankingScreen()),
                  ),
                ),
                IconButton(
                  tooltip: 'Filtros avanzados',
                  icon: Badge(
                    isLabelVisible: library.hasActiveFilters,
                    child: const Icon(Icons.filter_alt_outlined),
                  ),
                  onPressed: () => AppDialogs.showFilters(context),
                ),
                PopupMenuButton<_SortMode>(
                  tooltip: 'Ordenar',
                  icon: const Icon(Icons.sort),
                  onSelected: (_SortMode value) => setState(() => _sort = value),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<_SortMode>>[
                    _ordenItem('Añadidas recientemente', _SortMode.recientes),
                    _ordenItem('Título (A-Z)', _SortMode.titulo),
                    _ordenItem('Artista (A-Z)', _SortMode.artista),
                    _ordenItem('Álbum (A-Z)', _SortMode.album),
                    _ordenItem('Año (nuevo primero)', _SortMode.anio),
                    _ordenItem('Duración (larga primero)', _SortMode.duracion),
                    _ordenItem('Más escuchadas', _SortMode.reproducciones),
                  ],
                ),
                IconButton(
                  tooltip: 'Modo coche',
                  icon: const Icon(Icons.directions_car_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CarModeScreen(),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Letra de la canción',
                  icon: const Icon(Icons.lyrics_outlined),
                  onPressed: () {
                    final Song? actual = player.current;
                    if (actual == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Primero pon algo a sonar')),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LyricsScreen(song: actual),
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Reproducción aleatoria de todo',
                  icon: const Icon(Icons.shuffle),
                  onPressed: () async {
                    if (songs.isEmpty) return;
                    // Aleatorio de verdad: se elige una canción al azar y se
                    // reproduce directamente. Antes se cargaba la cola desde
                    // la primera canción con `autoPlay: false`, pero si ya
                    // había música sonando esa primera canción arrancaba
                    // igual y sumaba una reproducción al ranking.
                    final int azar = Random().nextInt(songs.length);
                    if (!player.isShuffleEnabled) player.toggleShuffle();
                    await player.setQueue(songs, startIndex: azar, autoPlay: true);
                  },
                ),
              ],
      ),
      body: Column(
        children: <Widget>[
          if (library.hasActiveFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _filterSummary(library),
                      style: const TextStyle(fontSize: 12.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: library.clearFilters,
                    child: const Text('Quitar filtros'),
                  ),
                ],
              ),
            ),
          if (library.isLoading) const LinearProgressIndicator(minHeight: 2),
          if (library.importProgress > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    library.importMessage ?? 'Importando…',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(value: library.importProgress, minHeight: 4),
                ],
              ),
            ),
          Expanded(
            child: songs.isEmpty
                ? EmptyState(
                    icon: Icons.library_music_outlined,
                    title: library.songs.isEmpty
                        ? 'Tu biblioteca está vacía'
                        : 'Sin resultados',
                    message: library.songs.isEmpty
                        ? 'Importa tus canciones (MP3, M4A, OGG, FLAC, WAV…) desde el botón inferior.\n'
                            'BotMp3 también funciona 100 % sin conexión.'
                        : 'Prueba con otros filtros o términos de búsqueda.',
                    actionLabel: library.songs.isEmpty ? 'Importar canciones' : null,
                    onAction: library.songs.isEmpty ? () => AppDialogs.importSongs(context) : null,
                  )
                : RefreshIndicator(
                    onRefresh: library.init,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 96, top: 4),
                      itemCount: songs.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Song song = songs[index];
                        return SongTile(
                          song: song,
                          queueContext: songs,
                          selected: _selected.contains(song.id),
                          // Solo en modo selección el toque marca/desmarca.
                          onTap: _selectionMode
                              ? () => setState(() {
                                    if (_selected.contains(song.id)) {
                                      _selected.remove(song.id);
                                    } else {
                                      _selected.add(song.id);
                                    }
                                    if (_selected.isEmpty) _selectionMode = false;
                                  })
                              : null,
                          onSelected: (bool value) => setState(() {
                            _selectionMode = true;
                            if (value) {
                              _selected.add(song.id);
                            } else {
                              _selected.remove(song.id);
                            }
                            if (_selected.isEmpty) _selectionMode = false;
                          }),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _filterSummary(LibraryProvider library) {
    final List<String> parts = <String>[];
    if (library.genreFilter != null) parts.add('Género: ${library.genreFilter}');
    if (library.artistFilter != null) parts.add('Artista: ${library.artistFilter}');
    if (library.yearFrom != null) parts.add('Año: ${library.yearFrom}');
    if (library.tagFilters.isNotEmpty) parts.add('Tags: ${library.tagFilters.join(', ')}');
    if (library.favoritesOnly) parts.add('Solo favoritas');
    return parts.isEmpty ? 'Todos los filtros' : parts.join(' · ');
  }
}

/// Formato corto reutilizado por varias pantallas.
String songDurationLabel(Song song) => Formatters.durationFromMs(song.durationMs);

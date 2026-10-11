import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import 'ranking_screen.dart';
import '../widgets/dialogs.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_tile.dart';

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

  List<Song> _sorted(List<Song> input) {
    final List<Song> songs = List<Song>.from(input);
    switch (_sort) {
      case _SortMode.recientes:
        songs.sort((Song a, Song b) => b.addedAt.compareTo(a.addedAt));
      case _SortMode.titulo:
        songs.sort((Song a, Song b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case _SortMode.artista:
        songs.sort((Song a, Song b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
      case _SortMode.album:
        songs.sort((Song a, Song b) => a.album.toLowerCase().compareTo(b.album.toLowerCase()));
      case _SortMode.anio:
        songs.sort((Song a, Song b) => b.year.compareTo(a.year));
      case _SortMode.duracion:
        songs.sort((Song a, Song b) => b.durationMs.compareTo(a.durationMs));
      case _SortMode.reproducciones:
        songs.sort((Song a, Song b) => b.playCount.compareTo(a.playCount));
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
                    const PopupMenuItem<_SortMode>(value: _SortMode.recientes, child: Text('Añadidas recientemente')),
                    const PopupMenuItem<_SortMode>(value: _SortMode.titulo, child: Text('Título (A-Z)')),
                    const PopupMenuItem<_SortMode>(value: _SortMode.artista, child: Text('Artista (A-Z)')),
                    const PopupMenuItem<_SortMode>(value: _SortMode.album, child: Text('Álbum (A-Z)')),
                    const PopupMenuItem<_SortMode>(value: _SortMode.anio, child: Text('Año (nuevo primero)')),
                    const PopupMenuItem<_SortMode>(value: _SortMode.duracion, child: Text('Duración')),
                    const PopupMenuItem<_SortMode>(value: _SortMode.reproducciones, child: Text('Más escuchadas')),
                  ],
                ),
                IconButton(
                  tooltip: 'Reproducción aleatoria de todo',
                  icon: const Icon(Icons.shuffle),
                  onPressed: () async {
                    if (songs.isEmpty) return;
                    await player.setQueue(songs, autoPlay: false);
                    if (!player.isShuffleEnabled) player.toggleShuffle();
                    await player.next();
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

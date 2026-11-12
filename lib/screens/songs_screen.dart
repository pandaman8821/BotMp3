import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters.dart';
import '../core/text_utils.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import 'ranking_screen.dart';
import '../core/theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/skeleton.dart';
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

  @override
  void initState() {
    super.initState();
    _cargarOrden();
  }

  /// Recupera el ultimo orden usado (persistente entre sesiones).
  Future<void> _cargarOrden() async {
    final SettingsService ajustes = await SettingsService.instance();
    final String guardado = ajustes.ordenBiblioteca;
    final _SortMode modo = _SortMode.values.firstWhere(
      (_SortMode m) => m.name == guardado,
      orElse: () => _SortMode.recientes,
    );
    if (!mounted || modo == _sort) return;
    setState(() => _sort = modo);
  }

  /// Guarda el orden para la proxima vez.
  Future<void> _guardarOrden(_SortMode modo) async {
    final SettingsService ajustes = await SettingsService.instance();
    await ajustes.setOrdenBiblioteca(modo.name);
  }
  bool _selectionMode = false;
  final Set<String> _selected = <String>{};


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

  /// Edicion en lote: aplica artista/album/genero a la seleccion.
  Future<void> _editarSeleccion(List<Song> canciones) async {
    final AppLocalizations loc = AppLocalizations.of(context);
    final TextEditingController artista = TextEditingController();
    final TextEditingController album = TextEditingController();
    final TextEditingController genero = TextEditingController();
    final bool? aplicar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(loc.batchEdit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(controller: artista, decoration: InputDecoration(labelText: loc.artistStar)),
            TextField(controller: album, decoration: InputDecoration(labelText: loc.albumLabel)),
            TextField(controller: genero, decoration: InputDecoration(labelText: loc.genreStar)),
            const SizedBox(height: 6),
            Text(loc.batchEditHint, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(loc.cancel)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(loc.saveChanges)),
        ],
      ),
    );
    if (aplicar != true) return;
    final LibraryProvider library = context.read<LibraryProvider>();
    for (final Song cancion in canciones) {
      Song actualizada = cancion;
      if (artista.text.trim().isNotEmpty) actualizada = actualizada.copyWith(artist: artista.text.trim());
      if (album.text.trim().isNotEmpty) actualizada = actualizada.copyWith(album: album.text.trim());
      if (genero.text.trim().isNotEmpty) actualizada = actualizada.copyWith(genre: genero.text.trim());
      if (actualizada != cancion) await library.saveSong(actualizada);
    }
    if (!mounted) return;
    setState(() {
      _selectionMode = false;
      _selected.clear();
    });
  }

  /// Menu de orden en hoja inferior (mas moderno que el menu clasico).
  Future<void> _mostrarMenuOrden(BuildContext context) async {
    final AppLocalizations loc = AppLocalizations.of(context);
    final _SortMode? elegido = await showModalBottomSheet<_SortMode>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.sort_rounded),
                title: Text(loc.sortBy, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              for (final (String texto, _SortMode modo) in <(String, _SortMode)>[
                (loc.sortRecent, _SortMode.recientes),
                (loc.sortTitle, _SortMode.titulo),
                (loc.sortArtist, _SortMode.artista),
                (loc.sortAlbum, _SortMode.album),
                (loc.sortYear, _SortMode.anio),
                (loc.sortDuration, _SortMode.duracion),
                (loc.sortMostPlayed, _SortMode.reproducciones),
              ])
                ListTile(
                  leading: Icon(
                    _sort == modo ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: _sort == modo ? AppColors.green : null,
                  ),
                  title: Text(texto),
                  onTap: () => Navigator.of(sheetContext).pop(modo),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (elegido == null || elegido == _sort) return;
    setState(() => _sort = elegido);
    _guardarOrden(elegido);
  }

  @override
  Widget build(BuildContext context) {
    final LibraryProvider library = context.watch<LibraryProvider>();
    final PlayerProvider player = context.watch<PlayerProvider>();
    final List<Song> songs = _sorted(library.visibleSongs);

    return Scaffold(
      appBar: AppBar(
        actionsIconTheme: const IconThemeData(size: 20),
        titleSpacing: 6,
        title: _selectionMode
            ? Text('${_selected.length} seleccionadas', style: const TextStyle(fontSize: 18))
            : const FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: TituloBotMp3(tamano: 21),
              ),
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
                  tooltip: AppLocalizations.of(context).addToPlaylist,
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
                  tooltip: AppLocalizations.of(context).batchEdit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    final List<Song> elegidas =
                        songs.where((Song song) => _selected.contains(song.id)).toList();
                    if (elegidas.isNotEmpty) _editarSeleccion(elegidas);
                  },
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context).playSelection,
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {
                    final List<Song> chosen =
                        songs.where((Song song) => _selected.contains(song.id)).toList();
                    if (chosen.isNotEmpty) player.setQueue(chosen);
                  },
                ),
              ]
            : <Widget>[
                SizedBox(
                  width: 6 * 34.0,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        BotonAccion(
                          icono: Icons.leaderboard_rounded,
                          tooltip: AppLocalizations.of(context).mostPlayedRanking,
                          tamano: 20,
                          anchoAlto: 34,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const RankingScreen()),
                          ),
                        ),
                        BotonAccion(
                          icono: Icons.sort_rounded,
                          tooltip: AppLocalizations.of(context).sortBy,
                          tamano: 20,
                          anchoAlto: 34,
                          onPressed: () => _mostrarMenuOrden(context),
                        ),
                        BotonAccion(
                          icono: library.hasActiveFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                          tooltip: AppLocalizations.of(context).advancedFilters,
                          activo: library.hasActiveFilters,
                          tamano: 20,
                          anchoAlto: 34,
                          onPressed: () => AppDialogs.showFilters(context),
                        ),
                        BotonAccion(
                          icono: Icons.shuffle_rounded,
                          tooltip: AppLocalizations.of(context).shuffleAll,
                          tamano: 20,
                          anchoAlto: 34,
                          onPressed: () async {
                            if (songs.isEmpty) return;
                            final int azar = Random().nextInt(songs.length);
                            if (!player.isShuffleEnabled) player.toggleShuffle();
                            await player.setQueue(songs, startIndex: azar, autoPlay: true);
                          },
                        ),
                        BotonAccion(
                          icono: Icons.directions_car_rounded,
                          tooltip: AppLocalizations.of(context).carMode,
                          tamano: 20,
                          anchoAlto: 34,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const CarModeScreen()),
                          ),
                        ),
                        BotonAccion(
                          icono: Icons.lyrics_rounded,
                          tooltip: AppLocalizations.of(context).songLyrics,
                          tamano: 20,
                          anchoAlto: 34,
                          onPressed: () {
                            final Song? actual = context.read<PlayerProvider>().current;
                            if (actual == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppLocalizations.of(context).playSomethingFirst)),
                              );
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => LyricsScreen(song: actual)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
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
                    child: Text(AppLocalizations.of(context).clearFilters),
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
            child: library.isLoading && songs.isEmpty
                ? const ListaSkeleton()
                : songs.isEmpty
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
                          // Solo se pinta la seleccion si de verdad se esta
                          // seleccionando: si no, una marca antigua dejaba una fila
                          // resaltada como si estuviera elegida.
                          selected:
                              _selectionMode && _selected.contains(song.id),
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

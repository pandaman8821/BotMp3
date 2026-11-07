import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/cover_art.dart';
import 'playlists_screen.dart';

/// Pantalla de inicio: portada de la app con secciones utiles.
///
/// - Continuar escuchando (canción actual)
/// - Añadido recientemente
/// - Favoritas
/// - Más escuchadas
/// - Tus playlists
class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);
    final LibraryProvider library = context.watch<LibraryProvider>();
    final PlayerProvider player = context.watch<PlayerProvider>();
    final List<Song> canciones = library.visibleSongs;

    return Scaffold(
      appBar: AppBar(
        title: Text('BotMp3'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 140),
        children: <Widget>[
          if (library.isScanning)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  LinearProgressIndicator(value: library.importProgress > 0 ? library.importProgress : null),
                  const SizedBox(height: 4),
                  Text(library.scanMessage ?? loc.homeScanning, style: TextStyle(fontSize: 12, color: AppColors.darkTextDim)),
                ],
              ),
            ),
          if (canciones.isEmpty)
            _Vacio(escanear: () {
              library.autoScan(force: true);
            })
          else ...<Widget>[
            if (player.current != null) ...<Widget>[
              _Titulo( texto: loc.homeContinue),
              _Continuar(song: player.current!, player: player),
            ],
            _Titulo(texto: loc.homeRecent),
            _FilaHorizontal(canciones: _recientes(canciones), player: player, subtituloAnio: true),
            if (canciones.any((Song s) => s.isFavorite)) ...<Widget>[
              _Titulo(texto: loc.homeFavorites),
              _FilaHorizontal(canciones: _favoritas(canciones), player: player),
            ],
            _Titulo(texto: loc.homeMostPlayed),
            _FilaHorizontal(canciones: _masEscuchadas(canciones), player: player, mostrarReproducciones: true),
            if (library.playlists.isNotEmpty) ...<Widget>[
              _Titulo(texto: loc.homePlaylists),
              _Playlists(playlists: library.playlists, library: library),
            ],
          ],
        ],
      ),
    );
  }

  static List<Song> _recientes(List<Song> canciones) {
    final List<Song> copia = List<Song>.from(canciones)
      ..sort((Song a, Song b) => b.addedAt.compareTo(a.addedAt));
    return copia.take(10).toList();
  }

  static List<Song> _favoritas(List<Song> canciones) {
    final List<Song> copia = canciones.where((Song s) => s.isFavorite).toList()
      ..sort((Song a, Song b) => b.addedAt.compareTo(a.addedAt));
    return copia.take(10).toList();
  }

  static List<Song> _masEscuchadas(List<Song> canciones) {
    final List<Song> copia = List<Song>.from(canciones)
      ..sort((Song a, Song b) {
        final int porReproducciones = b.playCount.compareTo(a.playCount);
        return porReproducciones != 0 ? porReproducciones : a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    return copia.take(10).toList();
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(texto, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

class _Continuar extends StatelessWidget {
  const _Continuar({required this.song, required this.player});
  final Song song;
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => player.play(),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: <Widget>[
                CoverArt(path: song.coverPath, size: 60, borderRadius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.darkTextDim, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(player.playing ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 42, color: AppColors.green),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaHorizontal extends StatelessWidget {
  const _FilaHorizontal({
    required this.canciones,
    required this.player,
    this.subtituloAnio = false,
    this.mostrarReproducciones = false,
  });

  final List<Song> canciones;
  final PlayerProvider player;
  final bool subtituloAnio;
  final bool mostrarReproducciones;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: canciones.length,
        itemBuilder: (BuildContext context, int i) {
          final Song song = canciones[i];
          final String subtitulo = mostrarReproducciones
              ? '${song.playCount}'
              : (subtituloAnio && song.year > 0 ? '${song.year}' : song.artist);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: 124,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => player.playSong(song, context: canciones),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CoverArt(path: song.coverPath, size: 124, borderRadius: 12),
                    const SizedBox(height: 6),
                    Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(subtitulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: AppColors.darkTextDim)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Playlists extends StatelessWidget {
  const _Playlists({required this.playlists, required this.library});
  final List<Playlist> playlists;
  final LibraryProvider library;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: playlists.length,
        itemBuilder: (BuildContext context, int i) {
          final Playlist lista = playlists[i];
          final int total = library.songsOf(lista).length;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: 124,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PlaylistsScreen()),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CoverArt(path: lista.coverPath, size: 124, borderRadius: 12),
                    const SizedBox(height: 6),
                    Text(lista.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('$total', style: TextStyle(fontSize: 11, color: AppColors.darkTextDim)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.escanear});
  final VoidCallback escanear;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: <Widget>[
          const Icon(Icons.library_music_outlined, size: 64),
          const SizedBox(height: 12),
          Text(loc.homeEmpty, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: escanear,
            icon: const Icon(Icons.search),
            label: Text(loc.homeScanNow),
          ),
        ],
      ),
    );
  }
}
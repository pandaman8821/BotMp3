import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/cover_art.dart';

/// Pantalla de detalle de un album: portada, artista, año y sus canciones.
///
/// Se puede reproducir entero ("Reproducir todo") o en aleatorio ("Aleatorio").
class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key, required this.album});

  final String album;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);
    final LibraryProvider library = context.watch<LibraryProvider>();
    final PlayerProvider player = context.watch<PlayerProvider>();

    final List<Song> canciones = library.visibleSongs
        .where((Song s) => s.album.trim().toLowerCase() == album.trim().toLowerCase())
        .toList()
      ..sort((Song a, Song b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    final String artista = canciones.isEmpty
        ? ''
        : canciones.map((Song s) => s.artist.trim()).where((String a) => a.isNotEmpty).fold<String>(
              '',
              (String prev, String actual) => prev.isEmpty ? actual : (prev == actual ? prev : prev),
            );
    final int anio = canciones.isEmpty ? 0 : canciones.first.year;

    return Scaffold(
      appBar: AppBar(
        title: Text(album),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                CoverArt(
                  path: canciones.isNotEmpty ? canciones.first.coverPath : null,
                  size: 112,
                  borderRadius: 16,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        album,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (artista.isNotEmpty)
                        Text(artista, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.darkTextDim)),
                      Text(
                        loc.albumSongsCount(canciones.length),
                        style: TextStyle(color: AppColors.darkTextDim, fontSize: 12),
                      ),
                      if (anio > 0) Text('$anio', style: TextStyle(color: AppColors.darkTextDim, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canciones.isEmpty
                        ? null
                        : () => player.playSong(canciones.first, context: canciones),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(loc.playAll),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canciones.isEmpty
                        ? null
                        : () {
                            final List<Song> mezcla = List<Song>.from(canciones)..shuffle();
                            player.playSong(mezcla.first, context: mezcla);
                          },
                    icon: const Icon(Icons.shuffle),
                    label: Text(loc.shuffleAll),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final Song cancion in canciones)
            ListTile(
              leading: CoverArt(path: cancion.coverPath, size: 44),
              title: Text(cancion.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(cancion.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(_duracion(cancion.durationMs), style: TextStyle(color: AppColors.darkTextDim, fontSize: 12)),
              onTap: () => player.playSong(cancion, context: canciones),
            ),
        ],
      ),
    );
  }

  static String _duracion(int ms) {
    if (ms <= 0) return '—';
    final int total = (ms / 1000).round();
    final int m = total ~/ 60;
    final int s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
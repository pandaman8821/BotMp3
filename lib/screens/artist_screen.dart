import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/cover_art.dart';
import 'album_screen.dart';

/// Pantalla de artista: sus albums y canciones, con reproducir todo/aleatorio.
class ArtistScreen extends StatelessWidget {
  const ArtistScreen({super.key, required this.artist});

  final String artist;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);
    final LibraryProvider library = context.watch<LibraryProvider>();
    final PlayerProvider player = context.watch<PlayerProvider>();
    final String limpio = artist.trim().toLowerCase();

    final List<Song> canciones = library.visibleSongs
        .where((Song s) => s.artist.trim().toLowerCase() == limpio)
        .toList();
    final Map<String, List<Song>> porAlbum = <String, List<Song>>{};
    for (final Song s in canciones) {
      final String clave = s.album.trim().isEmpty ? '—' : s.album.trim();
      porAlbum.putIfAbsent(clave, () => <Song>[]).add(s);
    }
    final List<String> albums = porAlbum.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text(artist), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.darkSurfaceHigh,
                  child: Text(
                    artist.trim().isEmpty ? '?' : artist.trim()[0].toUpperCase(),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(artist, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      Text(loc.albumSongsCount(canciones.length), style: TextStyle(color: AppColors.darkTextDim, fontSize: 12)),
                      Text(loc.artistAlbums(albums.length), style: TextStyle(color: AppColors.darkTextDim, fontSize: 12)),
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
                    onPressed: canciones.isEmpty ? null : () => player.playSong(canciones.first, context: canciones),
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
          for (final String album in albums)
            ListTile(
              leading: CoverArt(path: porAlbum[album]!.first.coverPath, size: 52, borderRadius: 12),
              title: Text(album, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(loc.albumSongsCount(porAlbum[album]!.length), style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => AlbumScreen(album: album)),
              ),
            ),
        ],
      ),
    );
  }
}
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/cover_art.dart';
import '../widgets/dialogs.dart';

/// Busca canciones duplicadas (mismo titulo + artista, o mismo tamano y
/// duracion) y permite quitar las copias de la biblioteca sin borrar archivos.
class DuplicatesScreen extends StatelessWidget {
  const DuplicatesScreen({super.key});

  static String _clave(Song s) =>
      '${s.title.trim().toLowerCase()}|${s.artist.trim().toLowerCase()}';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);
    final LibraryProvider library = context.watch<LibraryProvider>();
    final PlayerProvider player = context.watch<PlayerProvider>();

    final Map<String, List<Song>> grupos = <String, List<Song>>{};
    for (final Song s in library.songs) {
      grupos.putIfAbsent(_clave(s), () => <Song>[]).add(s);
    }
    final List<List<Song>> repetidos =
        grupos.values.where((List<Song> g) => g.length > 1).toList()
          ..sort((List<Song> a, List<Song> b) => b.length.compareTo(a.length));

    return Scaffold(
      appBar: AppBar(title: Text(loc.duplicatesTitle), backgroundColor: Colors.transparent),
      body: repetidos.isEmpty
          ? Center(child: Text(loc.duplicatesEmpty, style: TextStyle(color: AppColors.darkTextDim)))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 120),
              itemCount: repetidos.length,
              itemBuilder: (BuildContext context, int i) {
                final List<Song> grupo = repetidos[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: AppColors.darkSurface,
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                '${grupo.first.title} — ${grupo.first.artist}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text('x${grupo.length}', style: TextStyle(color: AppColors.darkTextDim, fontSize: 12)),
                          ],
                        ),
                      ),
                      for (final Song s in grupo)
                        ListTile(
                          dense: true,
                          leading: CoverArt(path: s.coverPath, size: 40),
                          title: Text(s.path.split(Platform.pathSeparator).last, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                          trailing: Text(_mb(s.fileSizeBytes), style: TextStyle(color: AppColors.darkTextDim, fontSize: 11)),
                          onTap: () => player.playSong(s, context: grupo),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 6),
                          child: TextButton.icon(
                            icon: const Icon(Icons.cleaning_services_outlined, size: 18),
                            label: Text(loc.duplicatesRemove),
                            onPressed: () async {
                              final bool ok = await AppDialogs.confirm(
                                context,
                                title: loc.duplicatesRemove,
                                message: loc.duplicatesRemoveBody(grupo.length - 1),
                              );
                              if (!ok) return;
                              for (int k = 1; k < grupo.length; k++) {
                                await library.deleteSong(grupo[k].id);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  static String _mb(int bytes) => bytes <= 0 ? '—' : '${(bytes / 1048576).toStringAsFixed(1)} MB';
}
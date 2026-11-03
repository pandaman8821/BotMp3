import '../l10n/app_localizations.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/formatters.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../services/media_importer.dart';
import '../widgets/cover_art.dart';
import '../widgets/dialogs.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_tile.dart';

/// Gestión de listas de reproducción: crear, importar, exportar y abrir.
class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LibraryProvider library = context.watch<LibraryProvider>();
    final List<Playlist> playlists = library.playlists;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.tabPlaylists),
        actions: <Widget>[
          IconButton(
            tooltip: AppLocalizations.of(context)!.importListJson,
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _importJson(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final Playlist? playlist = await AppDialogs.createPlaylist(context);
          if (playlist != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.listCreated(playlist.name))),
            );
          }
        },
        icon: const Icon(Icons.playlist_add),
        label: Text(AppLocalizations.of(context)!.newPlaylist),
      ),
      body: playlists.isEmpty
          ? EmptyState(
              icon: Icons.queue_music_outlined,
              title: AppLocalizations.of(context)!.playlistsEmpty,
              message: AppLocalizations.of(context)!.playlistsEmptyDesc,
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 96, top: 6),
              itemCount: playlists.length,
              itemBuilder: (BuildContext context, int index) {
                final Playlist playlist = playlists[index];
                final List<Song> songs = library.songsOf(playlist);
                final String? cover = playlist.coverPath ??
                    (songs.isNotEmpty ? songs.first.coverPath : null);
                final Duration total = songs.fold(
                  Duration.zero,
                  (Duration sum, Song song) => sum + Duration(milliseconds: song.durationMs),
                );

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: CoverArt(path: cover, size: 58),
                    title: Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            playlist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (playlist.isAiGenerated)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.smart_toy, size: 16, color: Color(0xFF7C4DFF)),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (playlist.description.isNotEmpty)
                          Text(
                            playlist.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        Text(
                          '${songs.length} canciones · ${Formatters.duration(total)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (String action) =>
                          _playlistAction(context, playlist, action),
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(value: 'play', child: Text(AppLocalizations.of(context)!.play)),
                        PopupMenuItem<String>(value: 'shuffle', child: Text(AppLocalizations.of(context)!.shuffle)),
                        PopupMenuItem<String>(value: 'edit', child: Text(AppLocalizations.of(context)!.editNameDesc)),
                        PopupMenuItem<String>(value: 'export', child: Text(AppLocalizations.of(context)!.exportJson)),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _PlaylistSongsScreen(playlistId: playlist.id),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _playlistAction(BuildContext context, Playlist playlist, String action) async {
    final LibraryProvider library = context.read<LibraryProvider>();
    final PlayerProvider player = context.read<PlayerProvider>();
    final List<Song> songs = library.songsOf(playlist);

    switch (action) {
      case 'play':
        if (songs.isEmpty) {
          _snack(context, 'La lista está vacía');
          return;
        }
        await player.setQueue(songs);
      case 'shuffle':
        if (songs.isEmpty) {
          _snack(context, 'La lista está vacía');
          return;
        }
        await player.setQueue(songs, autoPlay: false);
        if (!player.isShuffleEnabled) player.toggleShuffle();
        await player.next();
      case 'edit':
        await AppDialogs.editPlaylist(context, playlist);
      case 'export':
        final String json = library.exportPlaylist(playlist);
        final String fileName = 'botmp3_${playlist.name.replaceAll(RegExp(r'[^\w]+'), '_')}.json';
        final String? path = await MediaImporter.exportText(fileName, json);
        if (context.mounted) {
          await Clipboard.setData(ClipboardData(text: json));
          _snack(
            context,
            path == null
                ? AppLocalizations.of(context)!.jsonCopied
                : 'Lista exportada y JSON copiado al portapapeles',
          );
        }
      case 'delete':
        final bool confirmed = await AppDialogs.confirm(
          context,
          title: AppLocalizations.of(context)!.deleteList,
          message: AppLocalizations.of(context)!.deleteListBody(playlist.name),
        );
        if (confirmed) await library.deletePlaylist(playlist.id);
    }
  }

  Future<void> _importJson(BuildContext context) async {
    final LibraryProvider library = context.read<LibraryProvider>();
    final String? content = await MediaImporter.pickJsonFile();
    if (content == null) return;
    final Playlist? playlist = await library.importPlaylistJson(content);
    if (!context.mounted) return;
    _snack(
      context,
      playlist == null
          ? 'El archivo no es una lista válida de BotMp3'
          : 'Lista "${playlist.name}" importada (${playlist.length} canciones)',
    );
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Detalle de una lista: reordenar, quitar, reproducir y exportar.
class _PlaylistSongsScreen extends StatelessWidget {
  const _PlaylistSongsScreen({required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context) {
    final LibraryProvider library = context.watch<LibraryProvider>();
    final PlayerProvider player = context.watch<PlayerProvider>();
    final Playlist? playlist = library.playlistById(playlistId);

    if (playlist == null) {
      return Scaffold(body: Center(child: Text(AppLocalizations.of(context)!.listNotFound)));
    }

    final List<Song> songs = library.songsOf(playlist);

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          IconButton(
            tooltip: AppLocalizations.of(context)!.play,
            icon: const Icon(Icons.play_arrow),
            onPressed: songs.isEmpty ? null : () => player.setQueue(songs),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.addSongs,
            icon: const Icon(Icons.playlist_add),
            onPressed: () async {
              final List<Song> chosen = await AppDialogs.pickSongs(
                context,
                candidates: library.songs,
                preselected: songs,
              );
              if (chosen.isEmpty) return;
              await library.addSongsToPlaylist(
                playlist.id,
                chosen.map((Song song) => song.id).toList(),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (String action) async {
              switch (action) {
                case 'edit':
                  await AppDialogs.editPlaylist(context, playlist);
                case 'export':
                  final String json = library.exportPlaylist(playlist);
                  final String? path = await MediaImporter.exportText(
                    'botmp3_${playlist.name.replaceAll(RegExp(r'[^\w]+'), '_')}.json',
                    json,
                  );
                  if (context.mounted) {
                    await Clipboard.setData(ClipboardData(text: json));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          path == null ? AppLocalizations.of(context)!.jsonCopied : AppLocalizations.of(context)!.exportedTo(path),
                        ),
                      ),
                    );
                  }
                case 'delete':
                  final bool confirmed = await AppDialogs.confirm(
                    context,
                    title: AppLocalizations.of(context)!.deleteList,
                    message: AppLocalizations.of(context)!.deleteListBodyShort(playlist.name),
                  );
                  if (confirmed && context.mounted) {
                    await library.deletePlaylist(playlist.id);
                    Navigator.of(context).pop();
                  }
                case 'cover':
                  final String? image = await MediaImporter.pickImage();
                  if (image != null) {
                    await library.updatePlaylist(playlist.copyWith(coverPath: image));
                  }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'edit', child: Text(AppLocalizations.of(context)!.editData)),
              PopupMenuItem<String>(value: 'cover', child: Text(AppLocalizations.of(context)!.changeCover)),
              PopupMenuItem<String>(value: 'export', child: Text(AppLocalizations.of(context)!.exportJson)),
              PopupMenuItem<String>(
                value: 'delete',
                child: Text(AppLocalizations.of(context)!.deleteList, style: const TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (playlist.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  playlist.description,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF9AA0B4)),
                ),
              ),
            ),
          if (playlist.isAiGenerated && playlist.aiPrompt != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: const Icon(Icons.smart_toy, size: 16),
                  label: Text(
                    'IA: ${playlist.aiPrompt}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          Expanded(
            child: songs.isEmpty
                ? EmptyState(
                    icon: Icons.music_off,
                    title: AppLocalizations.of(context)!.playlistEmptyTitle,
                    message: AppLocalizations.of(context)!.playlistEmptyDesc,
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: songs.length,
                    onReorder: (int oldIndex, int newIndex) {
                      final int target = newIndex > oldIndex ? newIndex - 1 : newIndex;
                      library.moveSongInPlaylist(playlist.id, oldIndex, target);
                    },
                    itemBuilder: (BuildContext context, int index) {
                      final Song song = songs[index];
                      return Dismissible(
                        key: ValueKey<String>('${playlist.id}_${song.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          color: Colors.redAccent.withAlpha(((0.85) * 255).round()),
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) =>
                            library.removeSongFromPlaylist(playlist.id, song.id),
                        child: SongTile(
                          song: song,
                          queueContext: songs,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(Formatters.durationFromMs(song.durationMs),
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 12),
                              ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_handle),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

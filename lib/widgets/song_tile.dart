import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../screens/cover_editor_screen.dart';
import '../screens/song_edit_screen.dart';
import 'cover_art.dart';
import 'dialogs.dart';

/// Tarjeta de canción reutilizable (biblioteca, búsqueda, listas, cola).
class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    this.queueContext,
    this.onTap,
    this.trailing,
    this.selected = false,
    this.onSelected,
    this.showMenu = true,
    this.dense = false,
  });

  final Song song;

  /// Cola que se cargará al pulsar (por ejemplo, el contenido de la lista).
  final List<Song>? queueContext;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final bool showMenu;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final LibraryProvider library = context.watch<LibraryProvider>();
    final PlayerProvider player = context.watch<PlayerProvider>();
    final Song current = library.songById(song.id) ?? song;
    final bool isCurrent = player.current?.id == song.id;

    return ListTile(
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.primary.withAlpha(((0.12) * 255).round()),
      contentPadding: EdgeInsets.symmetric(horizontal: dense ? 8 : 12, vertical: 4),
      leading: CoverArt(path: current.coverPath, size: dense ? 44 : 54),
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              current.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isCurrent ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ),
          if (current.isFavorite)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.favorite, size: 14, color: Colors.redAccent),
            ),
        ],
      ),
      subtitle: Text(
        current.subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12.5),
      ),
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                Formatters.durationFromMs(current.durationMs),
                style: const TextStyle(fontSize: 12),
              ),
              if (showMenu)
                IconButton(
                  tooltip: 'Opciones',
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showMenu(context, current),
                )
              else
                const SizedBox(width: 8),
            ],
          ),
      // Tocar reproduce de inmediato; la selección múltiple se activa con
      // una pulsación larga (o cuando la pantalla ya está en ese modo).
      onTap: onTap ?? () => player.playSong(current, context: queueContext),
      onLongPress: onSelected == null ? null : () => onSelected!(!selected),
    );
  }

  Future<void> _showMenu(BuildContext context, Song song) async {
    final PlayerProvider player = context.read<PlayerProvider>();
    final LibraryProvider library = context.read<LibraryProvider>();

    final String? action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Reproducir ahora'),
              onTap: () => Navigator.of(sheetContext).pop('play'),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_play),
              title: const Text('Reproducir a continuación'),
              onTap: () => Navigator.of(sheetContext).pop('next'),
            ),
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: const Text('Añadir a una lista'),
              onTap: () => Navigator.of(sheetContext).pop('playlist'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Editar metadatos y etiquetas'),
              onTap: () => Navigator.of(sheetContext).pop('edit'),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Editar carátula'),
              onTap: () => Navigator.of(sheetContext).pop('cover'),
            ),
            ListTile(
              leading: Icon(song.isFavorite ? Icons.favorite_border : Icons.favorite),
              title: Text(song.isFavorite ? 'Quitar de favoritas' : 'Marcar como favorita'),
              onTap: () => Navigator.of(sheetContext).pop('favorite'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Eliminar de la biblioteca', style: TextStyle(color: Colors.redAccent)),
              onTap: () => Navigator.of(sheetContext).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case 'play':
        await player.playSong(song, context: queueContext);
      case 'next':
        await player.playNext(song);
        if (context.mounted) _snack(context, '"${song.title}" suena a continuación');
      case 'playlist':
        await AppDialogs.addSongsToPlaylist(context, <Song>[song]);
      case 'edit':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => SongEditScreen(songId: song.id)),
        );
      case 'cover':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => CoverEditorScreen(songId: song.id)),
        );
      case 'favorite':
        await library.toggleFavorite(song.id);
      case 'delete':
        if (!context.mounted) return;
        final bool confirmed = await AppDialogs.confirm(
          context,
          title: 'Eliminar canción',
          message: 'Se quitará "${song.title}" de la biblioteca. El archivo no se borra del dispositivo.',
        );
        if (confirmed) await library.deleteSong(song.id);
    }
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

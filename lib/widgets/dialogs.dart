import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../services/media_importer.dart';

/// Diálogos reutilizables (crear lista, elegir lista, confirmar acciones).
class AppDialogs {
  const AppDialogs._();

  /// Crea una lista nueva (nombre + descripción obligatorios por diseño de UX).
  static Future<Playlist?> createPlaylist(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final LibraryProvider library = context.read<LibraryProvider>();

    final bool? accepted = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Nueva lista'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre de la lista'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Para qué momento es esta lista…',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (accepted != true) return null;
    final Playlist playlist = await library.createPlaylist(
      name: nameController.text,
      description: descriptionController.text,
    );
    nameController.dispose();
    descriptionController.dispose();
    return playlist;
  }

  /// Permite editar nombre y descripción de una lista existente.
  static Future<void> editPlaylist(BuildContext context, Playlist playlist) async {
    final TextEditingController nameController = TextEditingController(text: playlist.name);
    final TextEditingController descriptionController =
        TextEditingController(text: playlist.description);
    final LibraryProvider library = context.read<LibraryProvider>();

    final bool? accepted = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Editar lista'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (accepted == true) {
      await library.updatePlaylist(
        playlist.copyWith(
          name: nameController.text.trim().isEmpty
              ? playlist.name
              : nameController.text.trim(),
          description: descriptionController.text.trim(),
        ),
      );
    }
    nameController.dispose();
    descriptionController.dispose();
  }

  /// Selector de lista para añadir canciones.
  static Future<Playlist?> pickPlaylist(BuildContext context, {String title = 'Añadir a lista'}) async {
    final LibraryProvider library = context.read<LibraryProvider>();
    final List<Playlist> playlists = library.playlists;

    return showDialog<Playlist>(
      context: context,
      builder: (BuildContext dialogContext) => SimpleDialog(
        title: Text(title),
        children: <Widget>[
          if (playlists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Todavía no tienes listas. Crea una nueva.'),
            ),
          ...playlists.map(
            (Playlist playlist) => SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(playlist),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.queue_music, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      playlist.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Text('${playlist.length}', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          SimpleDialogOption(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await createPlaylist(context);
            },
            child: const Row(
              children: <Widget>[
                Icon(Icons.add, size: 22),
                SizedBox(width: 12),
                Text('Crear lista nueva', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Selección múltiple de canciones (para añadir a listas).
  static Future<List<Song>> pickSongs(
    BuildContext context, {
    required List<Song> candidates,
    List<Song> preselected = const <Song>[],
  }) async {
    final Set<String> selected = preselected.map((Song s) => s.id).toSet();
    final LibraryProvider library = context.read<LibraryProvider>();

    final bool? accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => StatefulBuilder(
        builder: (BuildContext innerContext, void Function(void Function()) setState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            builder: (_, ScrollController controller) => Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: <Widget>[
                      Text(
                        '${selected.length} seleccionadas',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        child: const Text('Añadir'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: candidates.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Song song = candidates[index];
                      final bool isSelected = selected.contains(song.id);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selected.add(song.id);
                            } else {
                              selected.remove(song.id);
                            }
                          });
                        },
                        title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          song.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (accepted != true) return <Song>[];
    return selected.map((String id) => library.songById(id)).whereType<Song>().toList();
  }

  /// Filtro avanzado: género, artista, rango de años y tags.
  ///
  /// Se usan chips en lugar de menús desplegables: son más cómodos con una mano
  /// y no dependen de APIs que cambian entre versiones de Flutter.
  static Future<void> showFilters(BuildContext context) async {
    final LibraryProvider library = context.read<LibraryProvider>();
    String? genre = library.genreFilter;
    String? artist = library.artistFilter;
    int? yearFrom = library.yearFrom;
    int? yearTo = library.yearTo;
    final Set<String> tags = Set<String>.from(library.tagFilters);
    bool favoritesOnly = library.favoritesOnly;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => StatefulBuilder(
        builder: (BuildContext innerContext, void Function(void Function()) setState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            builder: (_, ScrollController controller) => ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: <Widget>[
                const Text(
                  'Filtros avanzados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Género', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: <Widget>[
                    ChoiceChip(
                      label: const Text('Todos'),
                      selected: genre == null,
                      onSelected: (_) => setState(() => genre = null),
                    ),
                    ...GenreCatalog.all.map(
                      (String value) => ChoiceChip(
                        label: Text(value),
                        selected: genre == value,
                        onSelected: (bool selected) =>
                            setState(() => genre = selected ? value : null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Artista', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: <Widget>[
                    ChoiceChip(
                      label: const Text('Todos'),
                      selected: artist == null,
                      onSelected: (_) => setState(() => artist = null),
                    ),
                    ...library.artists.take(40).map(
                          (String value) => ChoiceChip(
                            label: Text(value, overflow: TextOverflow.ellipsis),
                            selected: artist == value,
                            onSelected: (bool selected) =>
                                setState(() => artist = selected ? value : null),
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Año', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: <Widget>[
                    ChoiceChip(
                      label: const Text('Cualquiera'),
                      selected: yearFrom == null && yearTo == null,
                      onSelected: (_) => setState(() {
                        yearFrom = null;
                        yearTo = null;
                      }),
                    ),
                    ...library.years.take(14).map(
                          (int value) => ChoiceChip(
                            label: Text('$value'),
                            selected: yearFrom == value || yearTo == value,
                            onSelected: (bool selected) => setState(() {
                              if (!selected) {
                                yearFrom = null;
                                yearTo = null;
                              } else if (yearFrom == null) {
                                yearFrom = value;
                                yearTo = value;
                              } else {
                                yearFrom = value < yearFrom! ? value : yearFrom;
                                yearTo = value > yearTo! ? value : yearTo;
                              }
                            }),
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Etiquetas', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: library.allTags.take(30).map((String tag) {
                    return FilterChip(
                      label: Text(tag),
                      selected: tags.contains(tag),
                      onSelected: (bool value) => setState(() {
                        if (value) {
                          tags.add(tag);
                        } else {
                          tags.remove(tag);
                        }
                      }),
                    );
                  }).toList(),
                ),
                SwitchListTile(
                  value: favoritesOnly,
                  onChanged: (bool value) => setState(() => favoritesOnly = value),
                  title: const Text('Solo favoritas'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          library.clearFilters();
                          Navigator.of(sheetContext).pop();
                        },
                        child: const Text('Limpiar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          library
                            ..setGenreFilter(genre)
                            ..setArtistFilter(artist)
                            ..setYearRange(yearFrom, yearTo);
                          for (final String tag in library.allTags.take(30)) {
                            final bool shouldHave = tags.contains(tag);
                            if (library.tagFilters.contains(tag) != shouldHave) {
                              library.toggleTagFilter(tag);
                            }
                          }
                          if (library.favoritesOnly != favoritesOnly) {
                            library.toggleFavoritesOnly();
                          }
                          Navigator.of(sheetContext).pop();
                        },
                        child: const Text('Aplicar filtros'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Confirmación genérica destructiva.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Eliminar',
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Añade las canciones seleccionadas a una lista (flujo completo).
  static Future<void> addSongsToPlaylist(BuildContext context, List<Song> songs) async {
    if (songs.isEmpty) return;
    final LibraryProvider library = context.read<LibraryProvider>();
    final Playlist? playlist = await pickPlaylist(context);
    if (playlist == null) return;
    await library.addSongsToPlaylist(
      playlist.id,
      songs.map((Song song) => song.id).toList(),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${songs.length} canción(es) añadidas a "${playlist.name}"')),
      );
    }
  }

  /// Importa canciones mostrando el progreso.
  static Future<void> importSongs(BuildContext context) async {
    final LibraryProvider library = context.read<LibraryProvider>();
    await MediaImporter.ensureAudioPermission();
    final List<String> paths = await MediaImporter.pickAudioFiles();
    if (paths.isEmpty) return;
    final int added = await library.importPaths(paths);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(added == 0 ? 'No se añadieron canciones nuevas' : '$added canciones importadas')),
      );
    }
  }
}

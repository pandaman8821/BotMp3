import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/formatters.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/ai_provider.dart';
import '../services/media_scanner.dart';
import '../services/metadata_service.dart';
import '../widgets/cover_art.dart';
import '../widgets/dialogs.dart';
import 'cover_editor_screen.dart';

/// Edición de metadatos y etiquetas de una canción.
///
/// Todos los campos obligatorios están presentes: título, artista, álbum, año,
/// género (selector) y duración. Las etiquetas extra alimentan la búsqueda
/// avanzada y las recomendaciones de la IA.
class SongEditScreen extends StatefulWidget {
  const SongEditScreen({super.key, required this.songId});

  final String songId;

  @override
  State<SongEditScreen> createState() => _SongEditScreenState();
}

class _SongEditScreenState extends State<SongEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _title;
  late TextEditingController _artist;
  late TextEditingController _album;
  late TextEditingController _year;
  late TextEditingController _tagInput;
  String _genre = 'Otro';
  late List<String> _tags;
  int _durationMs = 0;
  bool _durationLoading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final Song? song = context.read<LibraryProvider>().songById(widget.songId);
    _title = TextEditingController(text: song?.title ?? '');
    _artist = TextEditingController(text: song?.artist ?? '');
    _album = TextEditingController(text: song?.album ?? '');
    _year = TextEditingController(text: (song?.year ?? 0) == 0 ? '' : '${song!.year}');
    _tagInput = TextEditingController();
    _genre = song?.genre ?? 'Otro';
    _tags = List<String>.from(song?.tags ?? <String>[]);
    _durationMs = song?.durationMs ?? 0;
  }

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _album.dispose();
    _year.dispose();
    _tagInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LibraryProvider library = context.watch<LibraryProvider>();
    final Song? song = library.songById(widget.songId);

    if (song == null) {
      return const Scaffold(body: Center(child: Text('Canción no encontrada')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar metadatos'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Autocompletar con IA',
            icon: const Icon(Icons.auto_awesome),
            onPressed: _saving ? null : () => _autocompletarConIa(song),
          ),
          IconButton(
            tooltip: 'Eliminar de la biblioteca',
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: <Widget>[
            Row(
              children: <Widget>[
                CoverArt(path: song.coverPath, size: 96, borderRadius: 18),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      FilledButton.tonalIcon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CoverEditorScreen(songId: song.id),
                          ),
                        ),
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('Editar carátula'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _usarCaratulaDelAlbum(song),
                        icon: const Icon(Icons.album_outlined),
                        label: const Text('Carátula del álbum'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${song.extension.toUpperCase()} · ${Formatters.bytes(song.fileSizeBytes)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Título *'),
              textCapitalization: TextCapitalization.sentences,
              validator: (String? value) =>
                  (value == null || value.trim().isEmpty) ? 'El título es obligatorio' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _artist,
              decoration: const InputDecoration(labelText: 'Artista *'),
              textCapitalization: TextCapitalization.words,
              validator: (String? value) =>
                  (value == null || value.trim().isEmpty) ? 'El artista es obligatorio' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _album,
              decoration: const InputDecoration(labelText: 'Álbum'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _year,
                    decoration: const InputDecoration(labelText: 'Año'),
                    keyboardType: TextInputType.number,
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final int? year = int.tryParse(value.trim());
                      if (year == null || year < 1900 || year > 2100) {
                        return 'Año inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Duración *'),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _durationLoading
                                ? 'Detectando…'
                                : Formatters.durationFromMs(_durationMs),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Detectar duración',
                          icon: const Icon(Icons.refresh, size: 18),
                          onPressed: _detectDuration,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Género *', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: GenreCatalog.all.map((String genre) {
                return ChoiceChip(
                  label: Text(genre),
                  selected: _genre == genre,
                  onSelected: (_) => setState(() => _genre = genre),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Etiquetas (búsqueda avanzada)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _tagInput,
                    decoration: const InputDecoration(
                      hintText: 'Añadir etiqueta y pulsar +',
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                IconButton(onPressed: _addTag, icon: const Icon(Icons.add_circle)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: <Widget>[
                ..._tags.map(
                  (String tag) => InputChip(
                    label: Text(tag),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                  ),
                ),
                ...TagSuggestions.all
                    .where((String tag) => !_tags.contains(tag))
                    .take(10)
                    .map(
                      (String tag) => ActionChip(
                        label: Text(tag),
                        onPressed: () => setState(() => _tags.add(tag)),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : () => _save(song),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Guardar cambios'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _writeTagsToFile(song),
              icon: const Icon(Icons.tag),
              label: const Text('Escribir etiquetas en el archivo'),
            ),
            const SizedBox(height: 6),
            const Text(
              'BotMp3 guarda los metadatos en su propia base de datos local y, además, '
              'puede escribirlos dentro del archivo (ID3/MP4/FLAC/OGG) cuando el formato lo permite.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9AA0B4)),
            ),
          ],
        ),
      ),
    );
  }

  void _addTag() {
    final String value = _tagInput.text.trim();
    if (value.isEmpty) return;
    setState(() {
      if (!_tags.contains(value)) _tags.add(value);
      _tagInput.clear();
    });
  }

  Future<void> _detectDuration() async {
    final Song? song = context.read<LibraryProvider>().songById(widget.songId);
    if (song == null) return;
    setState(() => _durationLoading = true);
    final int duration = await MetadataService().readDurationMs(song.path);
    if (!mounted) return;
    setState(() {
      _durationLoading = false;
      if (duration > 0) _durationMs = duration;
    });
  }

  /// Rellena el formulario con los datos corregidos por la IA (un solo toque).
  Future<void> _autocompletarConIa(Song song) async {
    final AiAssistantProvider ai = context.read<AiAssistantProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pidiendo los datos a la IA…')),
    );
    final Map<String, String>? sugerencia = await ai.suggestMetadata(song);
    if (!mounted) return;
    if (sugerencia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pude autocompletar. Revisa la API key en Ajustes ▸ IA.'),
        ),
      );
      return;
    }
    setState(() {
      final String titulo = sugerencia['titulo'] ?? '';
      final String artista = sugerencia['artista'] ?? '';
      final String album = sugerencia['album'] ?? '';
      final String anio = sugerencia['anio'] ?? '';
      final String genero = sugerencia['genero'] ?? '';
      final String tags = sugerencia['tags'] ?? '';
      if (titulo.isNotEmpty) _title.text = titulo;
      if (artista.isNotEmpty) _artist.text = artista;
      if (album.isNotEmpty) _album.text = album;
      if (anio.isNotEmpty) {
        _year.text = RegExp(r'\d{4}').firstMatch(anio)?.group(0) ?? _year.text;
      }
      if (genero.isNotEmpty) _genre = GenreCatalog.normalize(genero);
      if (tags.isNotEmpty) {
        _tags = tags
            .split(RegExp(r'[,\s]+'))
            .where((String tag) => tag.isNotEmpty)
            .toSet()
            .toList();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos completados ✨ Revisa y guarda')),
    );
  }

  /// Aplica como carátula la imagen original del álbum del dispositivo.
  Future<void> _usarCaratulaDelAlbum(Song song) async {
    final LibraryProvider library = context.read<LibraryProvider>();
    final String? path = await MediaScanner.albumArtForTrack(song.id);
    if (!mounted) return;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ese álbum no tiene carátula en el dispositivo')),
      );
      return;
    }
    await library.setCover(song.id, path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Carátula del álbum aplicada 🖼️')),
    );
  }

  Future<void> _save(Song song) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final LibraryProvider library = context.read<LibraryProvider>();

    final Song updated = song.copyWith(
      title: _title.text.trim(),
      artist: _artist.text.trim(),
      album: _album.text.trim(),
      year: int.tryParse(_year.text.trim()) ?? 0,
      genre: GenreCatalog.normalize(_genre),
      durationMs: _durationMs,
      tags: _tags,
    );

    await library.saveSong(updated);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Metadatos guardados')),
    );
  }

  Future<void> _writeTagsToFile(Song song) async {
    final Song updated = song.copyWith(
      title: _title.text.trim(),
      artist: _artist.text.trim(),
      album: _album.text.trim(),
      year: int.tryParse(_year.text.trim()) ?? 0,
      genre: GenreCatalog.normalize(_genre),
      tags: _tags,
    );
    final bool ok = await MetadataService().writeTags(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Etiquetas escritas en el archivo'
              : 'Este formato no permite escribir etiquetas; se guardaron solo en la app',
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final LibraryProvider library = context.read<LibraryProvider>();
    final bool confirmed = await AppDialogs.confirm(
      context,
      title: 'Eliminar canción',
      message: 'Se quitará de la biblioteca (el archivo de audio no se borra).',
    );
    if (!confirmed) return;
    await library.deleteSong(widget.songId);
    if (mounted) Navigator.of(context).pop();
  }
}

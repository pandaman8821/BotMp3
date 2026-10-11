import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../providers/library_provider.dart';
import '../services/cover_editor_service.dart';
import '../services/media_importer.dart';
import '../services/metadata_service.dart';
import '../widgets/cover_art.dart';

/// Editor de carátulas integrado: brillo, contraste, saturación, temperatura,
/// filtros, rotación, recorte con zoom/encuadre, texto/logo y exportación.
///
/// El procesado se hace en un isolate (`compute`) para no bloquear la interfaz
/// ni calentar el dispositivo.
class CoverEditorScreen extends StatefulWidget {
  const CoverEditorScreen({super.key, required this.songId});

  final String songId;

  @override
  State<CoverEditorScreen> createState() => _CoverEditorScreenState();
}

class _CoverEditorScreenState extends State<CoverEditorScreen> {
  final TextEditingController _textController = TextEditingController();

  Uint8List? _source;
  Uint8List? _preview;
  CoverEditState _state = const CoverEditState();
  bool _loading = true;
  bool _rendering = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final LibraryProvider library = context.read<LibraryProvider>();
    final Song? song = library.songById(widget.songId);
    Uint8List? bytes;

    try {
      final String? coverPath = song?.coverPath;
      if (coverPath != null && File(coverPath).existsSync()) {
        bytes = await File(coverPath).readAsBytes();
      } else if (song != null) {
        // Se intenta extraer la carátula incrustada en el archivo.
        final TrackTags? tags = await MetadataService().readTags(song.path);
        bytes = tags?.coverBytes;
      }
    } catch (_) {
      bytes = null;
    }

    if (!mounted) return;
    setState(() {
      _source = bytes;
      _loading = false;
    });
    if (bytes != null) _scheduleRender();
  }

  void _scheduleRender() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 260), _render);
  }

  Future<void> _render() async {
    final Uint8List? source = _source;
    if (source == null) return;
    setState(() => _rendering = true);
    try {
      final Uint8List rendered =
          await CoverEditorService.instance.render(source, _state);
      if (!mounted) return;
      setState(() {
        _preview = rendered;
        _rendering = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _rendering = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo procesar la imagen: $error')),
      );
    }
  }

  void _update(CoverEditState next, {bool render = true}) {
    setState(() => _state = next);
    if (render) _scheduleRender();
  }

  @override
  Widget build(BuildContext context) {
    final LibraryProvider library = context.watch<LibraryProvider>();
    final Song? song = library.songById(widget.songId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor de carátula'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Deshacer cambios',
            icon: const Icon(Icons.restart_alt),
            onPressed: () => _update(const CoverEditState()),
          ),
          IconButton(
            tooltip: 'Guardar en galería/almacenamiento',
            icon: const Icon(Icons.download_outlined),
            onPressed: _preview == null ? null : _exportToGallery,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Expanded(flex: 4, child: _buildPreview()),
                Expanded(
                  flex: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: <Widget>[
                        if (_source == null)
                          FilledButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.add_photo_alternate_outlined),
                            label: const Text('Elegir imagen (PNG/JPG)'),
                          ),
                        if (_source != null) ...<Widget>[                          _sectionTitle('Proporción'),
                          _sectionTitle('Acciones rápidas'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              ActionChip(
                                avatar: const Icon(Icons.rotate_right, size: 16),
                                label: const Text('Rotar 90°'),
                                onPressed: () => _update(_state.copyWith(
                                      quarterTurns: (_state.quarterTurns + 1) % 4,
                                    )),
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.auto_fix_high, size: 16),
                                label: const Text('Mejorar'),
                                onPressed: () => _update(_state.copyWith(
                                      brightness: 0.06,
                                      contrast: 0.14,
                                    )),
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.restart_alt, size: 16),
                                label: const Text('Original'),
                                onPressed: () => _update(const CoverEditState()),
                              ),
                            ],
                          ),

                          Wrap(
                            spacing: 8,
                            children: CoverAspect.values.map((CoverAspect aspect) {
                              return ChoiceChip(
                                label: Text(aspect.label),
                                selected: _state.aspect == aspect,
                                onSelected: (_) => _update(_state.copyWith(aspect: aspect)),
                              );
                            }).toList(),
                          ),
                          _sectionTitle('Rotación y encuadre'),
                          Row(
                            children: <Widget>[
                              OutlinedButton.icon(
                                onPressed: () => _update(
                                  _state.copyWith(quarterTurns: (_state.quarterTurns + 3) % 4),
                                ),
                                icon: const Icon(Icons.rotate_left),
                                label: const Text('90°'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => _update(
                                  _state.copyWith(quarterTurns: (_state.quarterTurns + 1) % 4),
                                ),
                                icon: const Icon(Icons.rotate_right),
                                label: const Text('90°'),
                              ),
                            ],
                          ),
                          _slider(
                            label: 'Zoom',
                            value: _state.zoom,
                            min: 1,
                            max: 3,
                            onChanged: (double v) => _update(_state.copyWith(zoom: v)),
                          ),
                          _slider(
                            label: 'Encuadre horizontal',
                            value: _state.offsetX,
                            min: -1,
                            max: 1,
                            onChanged: (double v) => _update(_state.copyWith(offsetX: v)),
                          ),
                          _slider(
                            label: 'Encuadre vertical',
                            value: _state.offsetY,
                            min: -1,
                            max: 1,
                            onChanged: (double v) => _update(_state.copyWith(offsetY: v)),
                          ),
                          _sectionTitle('Ajustes de imagen'),
                          _slider(
                            label: 'Brillo',
                            value: _state.brightness,
                            min: -0.5,
                            max: 0.5,
                            onChanged: (double v) => _update(_state.copyWith(brightness: v)),
                          ),
                          _slider(
                            label: 'Contraste',
                            value: _state.contrast,
                            min: -0.5,
                            max: 0.5,
                            onChanged: (double v) => _update(_state.copyWith(contrast: v)),
                          ),
                          _slider(
                            label: 'Saturación',
                            value: _state.saturation,
                            min: -1,
                            max: 1,
                            onChanged: (double v) => _update(_state.copyWith(saturation: v)),
                          ),
                          _slider(
                            label: 'Temperatura (frío ↔ cálido)',
                            value: _state.temperature,
                            min: -1,
                            max: 1,
                            onChanged: (double v) => _update(_state.copyWith(temperature: v)),
                          ),
                          _slider(
                            label: 'Velo / desvanecido',
                            value: _state.fade,
                            min: 0,
                            max: 0.6,
                            onChanged: (double v) => _update(_state.copyWith(fade: v)),
                          ),
                          _sectionTitle('Filtros'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: CoverFilter.values.map((CoverFilter filter) {
                              return ChoiceChip(
                                label: Text(filter.label),
                                selected: _state.filter == filter,
                                onSelected: (_) => _update(_state.copyWith(filter: filter)),
                              );
                            }).toList(),
                          ),
                          _sectionTitle('Texto o logo'),
                          TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              hintText: 'Texto sobre la carátula (opcional)',
                            ),
                            onChanged: (String value) =>
                                _update(_state.copyWith(text: value)),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: <Widget>[
                              for (final CoverTextPosition position in CoverTextPosition.values)
                                ChoiceChip(
                                  label: Text(position.name),
                                  selected: _state.textPosition == position,
                                  onSelected: (_) =>
                                      _update(_state.copyWith(textPosition: position)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            children: <int>[
                              0xFFFFFFFF,
                              0xFF000000,
                              0xFF1DB954,
                              0xFF7C4DFF,
                              0xFF00E0C6,
                              0xFFF59E0B,
                            ].map((int color) {
                              return GestureDetector(
                                onTap: () => _update(_state.copyWith(textColor: color)),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Color(color),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      width: _state.textColor == color ? 3 : 1,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          _slider(
                            label: 'Tamaño del texto',
                            value: _state.textSize,
                            min: 0.6,
                            max: 1.8,
                            onChanged: (double v) => _update(_state.copyWith(textSize: v)),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _rendering ? null : _applyToSong,
                            icon: const Icon(Icons.check),
                            label: const Text('Aplicar carátula a la canción'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _preview == null ? null : _exportToGallery,
                            icon: const Icon(Icons.ios_share),
                            label: const Text('Exportar (galería / almacenamiento)'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image_search),
                            label: const Text('Cambiar imagen base'),
                          ),
                        ],
                        if (song != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'Canción: ${song.title} — ${song.artist}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPreview() {
    final Uint8List? preview = _preview;
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: preview == null
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Sin imagen. Elige una foto (PNG/JPG) para empezar a editar la carátula.\n\n'
                'Puedes ajustar brillo, contraste, saturación, rotar, recortar, aplicar filtros '
                'y añadir texto.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            )
          : GestureDetector(
              onPanUpdate: (DragUpdateDetails details) {
                final double dx = (_state.offsetX + details.delta.dx / 220).clamp(-1.0, 1.0);
                final double dy = (_state.offsetY + details.delta.dy / 220).clamp(-1.0, 1.0);
                setState(() => _state = _state.copyWith(offsetX: dx, offsetY: dy));
              },
              onPanEnd: (_) => _scheduleRender(),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Image.memory(
                      preview,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                  if (_rendering)
                    const Positioned(
                      top: 12,
                      right: 12,
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      );

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5))),
            Text(value.toStringAsFixed(2), style: const TextStyle(fontSize: 12.5)),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }

  Future<void> _pickImage() async {
    final String? path = await MediaImporter.pickImage();
    if (path == null) return;
    try {
      final Uint8List bytes = await File(path).readAsBytes();
      setState(() {
        _source = bytes;
        _preview = null;
      });
      _scheduleRender();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la imagen: $error')),
      );
    }
  }

  Future<void> _applyToSong() async {
    final Uint8List? preview = _preview;
    if (preview == null) return;
    final LibraryProvider library = context.read<LibraryProvider>();
    final String path = await CoverEditorService.instance.save(preview, widget.songId);
    await library.setCover(widget.songId, path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Carátula aplicada a la canción ✅')),
    );
  }

  Future<void> _exportToGallery() async {
    final Uint8List? preview = _preview;
    if (preview == null) return;
    final String? saved = await MediaImporter.exportBytes(
      'botmp3_cover_${DateTime.now().millisecondsSinceEpoch}.jpg',
      preview,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved == null ? 'Exportación cancelada' : 'Carátula exportada a $saved',
        ),
      ),
    );
  }
}

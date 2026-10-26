import '../core/text_utils.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/ai_models.dart';
import '../models/song.dart';
import '../providers/ai_provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../services/settings_service.dart';
import '../services/voice_service.dart';
import '../widgets/cover_art.dart';
import '../widgets/wave_bars.dart';
import 'cover_editor_screen.dart';

/// Reproductor a pantalla completa: carátula grande, controles táctiles amplios,
/// cola de reproducción y "Modo DJ IA".
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _dragging = false;
  double _dragValue = 0;
  String? _lastDjSongId;
  bool _djBusy = false;
  String? _djMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRunAutoDj());
  }

  @override
  Widget build(BuildContext context) {
    final PlayerProvider player = context.watch<PlayerProvider>();
    final LibraryProvider library = context.watch<LibraryProvider>();
    final SettingsProvider settings = context.watch<SettingsProvider>();

    final Song? song = player.current;

    if (song == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reproduciendo')),
        body: const Center(child: Text('No hay ninguna canción en reproducción')),
      );
    }

    final Song current = library.songById(song.id) ?? song;
    final bool isFavorite = current.isFavorite;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
          tooltip: 'Cerrar',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Editar carátula',
            icon: const Icon(Icons.image_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CoverEditorScreen(songId: current.id),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cola de reproducción',
            icon: const Icon(Icons.queue_music),
            onPressed: () => _showQueue(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF1D1D28), AppColors.darkBg],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 8),
              // Carátula grande (se muestra a pantalla completa al reproducir).
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Hero(
                    tag: 'cover_${current.id}',
                    child: CoverArt(
                      path: current.coverPath,
                      size: MediaQuery.sizeOf(context).width - 56,
                      borderRadius: 26,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  current.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  current.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppColors.darkTextDim,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            iconSize: 30,
                            tooltip: isFavorite ? 'Quitar de favoritas' : 'Marcar favorita',
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.redAccent : null,
                            ),
                            onPressed: () => library.toggleFavorite(current.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: <Widget>[
                          if (current.album.isNotEmpty) Chip(label: Text(current.album)),
                          if (current.year > 0) Chip(label: Text('${current.year}')),
                          Chip(label: Text(current.genre)),
                          ...current.tags.take(3).map((String tag) => Chip(label: Text('#$tag'))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<Duration>(
                        stream: player.positionStream,
                        builder: (BuildContext context, AsyncSnapshot<Duration> snapshot) {
                          final Duration position = snapshot.data ?? Duration.zero;
                          final Duration total =
                              player.duration ?? Duration(milliseconds: current.durationMs);
                          final double max = total.inMilliseconds.toDouble().clamp(1, double.infinity);
                          final double value = _dragging
                              ? _dragValue
                              : position.inMilliseconds.toDouble().clamp(0, max);

                          return Column(
                            children: <Widget>[
                              Slider(
                                min: 0,
                                max: max,
                                value: value,
                                onChangeStart: (double v) => setState(() {
                                  _dragging = true;
                                  _dragValue = v;
                                }),
                                onChanged: (double v) => setState(() => _dragValue = v),
                                onChangeEnd: (double v) {
                                  player.seek(Duration(milliseconds: v.round()));
                                  setState(() => _dragging = false);
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      Formatters.duration(Duration(milliseconds: value.round())),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      Formatters.duration(total),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      // Controles principales (botones grandes)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          IconButton(
                            iconSize: 28,
                            tooltip: 'Aleatorio',
                            color: player.isShuffleEnabled ? AppColors.green : null,
                            icon: const Icon(Icons.shuffle),
                            onPressed: () => player.toggleShuffle(),
                          ),
                          IconButton(
                            iconSize: 42,
                            tooltip: 'Anterior',
                            icon: const Icon(Icons.skip_previous),
                            onPressed: player.previous,
                          ),
                          StreamBuilder<PlayerState>(
                            stream: player.playerStateStream,
                            builder: (BuildContext context, AsyncSnapshot<PlayerState> snapshot) {
                              final bool playing = snapshot.data?.playing ?? false;
                              final bool loading = snapshot.data?.processingState ==
                                      ProcessingState.loading ||
                                  snapshot.data?.processingState == ProcessingState.buffering;
                              return IconButton(
                                iconSize: 68,
                                tooltip: playing ? 'Pausar' : 'Reproducir',
                                color: AppColors.green,
                                icon: loading
                                    ? const SizedBox(
                                        width: 54,
                                        height: 54,
                                        child: CircularProgressIndicator(strokeWidth: 3),
                                      )
                                    : Icon(playing
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_fill),
                                onPressed: player.togglePlayPause,
                              );
                            },
                          ),
                          IconButton(
                            iconSize: 42,
                            tooltip: 'Siguiente',
                            icon: const Icon(Icons.skip_next),
                            onPressed: player.next,
                          ),
                          IconButton(
                            iconSize: 28,
                            tooltip: _repeatLabel(player.repeatMode),
                            color: player.repeatMode == RepeatMode.off ? null : AppColors.green,
                            icon: Icon(
                              player.repeatMode == RepeatMode.one ? Icons.repeat_one : Icons.repeat,
                            ),
                            onPressed: () {
                              final RepeatMode mode = player.cycleRepeatMode();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(_repeatLabel(mode))),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Acciones secundarias
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          _MiniAction(
                            icon: Icons.speed,
                            label: '${(player.speedPercent / 100).toStringAsFixed(2)}x',
                            onTap: () => _showSpeedSheet(context, player),
                          ),
                          _MiniAction(
                            icon: Icons.volume_up,
                            label: 'Volumen',
                            onTap: () => _showVolumeSheet(context, player),
                          ),
                          _MiniAction(
                            icon: Icons.smart_toy,
                            label: _djBusy ? '…' : 'DJ IA',
                            highlight: true,
                            onTap: _djBusy ? null : () => _runDj(context, manual: true),
                          ),
                          _MiniAction(
                            icon: Icons.info_outline,
                            label: 'Metadatos',
                            onTap: () => _showMetadata(context, current),
                          ),
                        ],
                      ),
                      if (_djMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Card(
                            color: const Color(0xFF1D1D28),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: <Widget>[
                                  const Icon(Icons.smart_toy, size: 18, color: AppColors.aiViolet),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _djMessage!,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (settings.showWaveAnimation)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Center(
                            child: WaveBars(
                              animate: !settings.batterySaver && player.playing,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _repeatLabel(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.off:
        return 'Sin repetición';
      case RepeatMode.all:
        return 'Repetir toda la cola';
      case RepeatMode.one:
        return 'Repetir esta canción';
    }
  }

  Future<void> _showSpeedSheet(BuildContext context, PlayerProvider player) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Velocidad de reproducción', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            Wrap(
              spacing: 8,
              children: <int>[50, 75, 100, 125, 150, 175, 200].map((int percent) {
                return ChoiceChip(
                  label: Text('${(percent / 100).toStringAsFixed(2)}x'),
                  selected: player.speedPercent == percent,
                  onSelected: (_) {
                    player.setSpeedPercent(percent);
                    Navigator.of(sheetContext).pop();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showVolumeSheet(BuildContext context, PlayerProvider player) async {
    double value = player.volume;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => StatefulBuilder(
        builder: (BuildContext innerContext, void Function(void Function()) setState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.volume_down),
                      Expanded(
                        child: Slider(
                          value: value,
                          onChanged: (double v) {
                            setState(() => value = v);
                            player.setVolume(v);
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up),
                    ],
                  ),
                  Text('${(value * 100).round()}%'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showMetadata(BuildContext context, Song song) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(song.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Artista: ${song.artist}'),
              Text('Álbum: ${song.album.isEmpty ? '—' : song.album}'),
              Text('Año: ${song.year == 0 ? '—' : song.year}'),
              Text('Género: ${song.genre}'),
              Text('Duración: ${Formatters.durationFromMs(song.durationMs)}'),
              Text('Formato: ${song.extension.toUpperCase()} · ${Formatters.bytes(song.fileSizeBytes)}'),
              if (song.tags.isNotEmpty) Text('Tags: ${song.tags.map((String t) => '#$t').join(' ')}'),
              const SizedBox(height: 8),
              Text(
                song.path,
                style: const TextStyle(fontSize: 11, color: AppColors.darkTextDim),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showQueue(BuildContext context) async {
    final PlayerProvider player = context.read<PlayerProvider>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, ScrollController controller) {
          final List<Song> queue = player.queue;
          return ListView.builder(
            controller: controller,
            itemCount: queue.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Cola de reproducción', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                );
              }
              final Song song = queue[index - 1];
              final bool isCurrent = player.current?.id == song.id;
              return ListTile(
                leading: CoverArt(path: song.coverPath, size: 44),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrent ? AppColors.green : null,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Quitar de la cola',
                  onPressed: () => player.removeFromQueue(song.id),
                ),
                onTap: () {
                  player.playAtIndex(index - 1);
                  Navigator.of(sheetContext).pop();
                },
              );
            },
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------------ DJ IA

  Future<void> _runDj(BuildContext context, {bool manual = false}) async {
    final PlayerProvider player = context.read<PlayerProvider>();
    final AiAssistantProvider ai = context.read<AiAssistantProvider>();
    final SettingsProvider settings = context.read<SettingsProvider>();
    final Song? current = player.current;
    if (current == null || _djBusy) return;

    if (!ai.hasActiveKey) {
      if (manual) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Configura la API key de ${ai.activeProvider.label} en Ajustes ▸ IA')),
        );
      }
      return;
    }

    setState(() => _djBusy = true);
    final AiActionResult? result = await ai.djNext(current, player.recentlyPlayed);
    if (!mounted) return;
    setState(() {
      _djBusy = false;
      _djMessage = result == null ? null : mensajeDelDJ(result.text);
    });

    final AiSongSuggestion? suggestion = result?.suggestions.isNotEmpty == true
        ? result!.suggestions.first
        : null;
    final LibraryProvider library = context.read<LibraryProvider>();
    final Song? nextSong = suggestion?.localSongId == null
        ? null
        : library.songById(suggestion!.localSongId!);

    if (nextSong != null) {
      await player.playNext(nextSong);
      if (settings.ttsEnabled) {
        await VoiceService.instance.speak(result?.text ?? 'Siguiente: ${nextSong.title}');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('DJ IA: a continuación "${nextSong.title}"')),
        );
      }
    } else if (manual && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result?.text ?? 'El DJ no encontró una canción adecuada')),
      );
    }
  }

  Future<void> _maybeRunAutoDj() async {
    final SettingsProvider settings = context.read<SettingsProvider>();
    final PlayerProvider player = context.read<PlayerProvider>();
    if (!settings.autoDj) return;
    final Song? current = player.current;
    if (current == null || current.id == _lastDjSongId) return;
    _lastDjSongId = current.id;
    await _runDj(context);
  }
}

/// Acción compacta de la fila secundaria (velocidad, volumen, DJ, metadatos).
class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final Color color = highlight ? AppColors.aiViolet : Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11.5, color: color)),
          ],
        ),
      ),
    );
  }
}

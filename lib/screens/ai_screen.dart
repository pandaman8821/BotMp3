import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/text_utils.dart';
import '../core/theme.dart';
import '../models/ai_models.dart';
import '../models/song.dart';
import 'trends_screen.dart';
import '../services/ai/action_executor.dart';
import '../providers/ai_provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../services/voice_service.dart';
import '../widgets/mini_player.dart';

/// Agente musical IA multimodelo: conversación, recomendaciones, listas
/// automáticas, búsqueda inteligente, Modo DJ y creación de canciones.
class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _listening = false;
  AiActionResult? _lastResult;
  AiSongIdea? _lastIdea;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AiAssistantProvider ai = context.watch<AiAssistantProvider>();
    final LibraryProvider library = context.watch<LibraryProvider>();
    final SettingsProvider settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('IA musical'),
        actions: <Widget>[
          IconButton(
            tooltip: settings.ttsEnabled ? 'Desactivar voz' : 'Leer respuestas en voz alta',
            icon: Icon(settings.ttsEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: () => settings.setTtsEnabled(!settings.ttsEnabled),
          ),
          IconButton(
            tooltip: 'Borrar conversación',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              final bool ok = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext dialogContext) => AlertDialog(
                      title: const Text('Borrar conversación'),
                      content: const Text('Se eliminará el historial con la IA.'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                          child: const Text('Borrar'),
                        ),
                      ],
                    ),
                  ) ??
                  false;
              if (ok) ai.clearHistory();
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _providerBar(context, ai),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    library.summaryLabel,
                    style: const TextStyle(fontSize: 12, color: AppColors.darkTextDim),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (ai.hasActiveKey)
                  TextButton.icon(
                    onPressed: () => _testConnection(context, ai),
                    icon: const Icon(Icons.wifi_tethering, size: 16),
                    label: const Text('Probar'),
                  ),
              ],
            ),
          ),
          if (ai.busy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ai.messages.isEmpty && _lastResult == null
                ? _emptyState(context)
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    children: <Widget>[
                      ...ai.messages.map((AiMessage message) => _bubble(context, message, ai)),
                      if (_lastResult != null) _resultCard(context, _lastResult!, ai, library),
                      if (_lastIdea != null) _ideaCard(context, _lastIdea!),
                    ],
                  ),
          ),
          _executedActions(ai),
          _quickActions(context, ai, library),
          _inputBar(context, ai, settings),
        ],
      ),
    );
  }

  Widget _providerBar(BuildContext context, AiAssistantProvider ai) {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: <Widget>[
          for (final AiProvider provider in AiProvider.values)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              child: ChoiceChip(
                avatar: Icon(
                  provider.icon,
                  size: 18,
                  color: ai.keyFor(provider) == null ? Colors.grey : null,
                ),
                label: Text(
                  ai.keyFor(provider) == null ? '${provider.label} (sin key)' : provider.label,
                ),
                selected: ai.activeProvider == provider,
                onSelected: (_) => ai.selectProvider(provider),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return EmptyState(
      icon: Icons.smart_toy_outlined,
      title: 'Tu DJ con IA',
      message: 'Pídele cosas como:\n'
          '• "recomiéndame 10 canciones de rock latino 2020-2025"\n'
          '• "hazme una playlist de 30 canciones para entrenar"\n'
          '• "algo tranquilo para estudiar un domingo"\n'
          '• "crea una canción de cumbia sobre Bolivia"',
      actionLabel: 'Configurar API keys',
      onAction: () {
        final AiAssistantProvider ai = context.read<AiAssistantProvider>();
        showDialog<void>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Proveedores de IA'),
            content: Text(
              'Añade al menos una API key en la pestaña Ajustes ▸ IA. '
              'Proveedor activo: ${ai.activeProvider.label}.',
            ),
            actions: <Widget>[
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bubble(BuildContext context, AiMessage message, AiAssistantProvider ai) {
    final bool isUser = message.isUser;
    final Color color = isUser
        ? Theme.of(context).colorScheme.primary.withAlpha(((0.18) * 255).round())
        : message.error
            ? Colors.red.withAlpha(((0.15) * 255).round())
            : AppColors.aiViolet.withAlpha(((0.14) * 255).round());

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!isUser)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.smart_toy, size: 15, color: AppColors.aiCyan),
                  const SizedBox(width: 6),
                  Text(
                    message.provider?.label ?? 'IA',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            if (!isUser) const SizedBox(height: 4),
            SelectableText(
              // El texto de la IA se muestra limpio: sin markdown ni bloques
              // internos de órdenes, y con tono de conversación.
              isUser ? message.content : textoHumano(message.content),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultCard(
    BuildContext context,
    AiActionResult result,
    AiAssistantProvider ai,
    LibraryProvider library,
  ) {
    final PlayerProvider player = context.read<PlayerProvider>();
    final List<Song> localSongs = result.suggestions
        .map((AiSongSuggestion suggestion) => suggestion.localSongId)
        .whereType<String>()
        .map(library.songById)
        .whereType<Song>()
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.auto_awesome, size: 18, color: AppColors.aiCyan),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.playlistName ?? 'Recomendaciones',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ],
            ),
            if (result.playlistDescription != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  result.playlistDescription!,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.darkTextDim),
                ),
              ),
            const SizedBox(height: 10),
            ...result.suggestions.take(30).map((AiSongSuggestion suggestion) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  suggestion.isLocal ? Icons.play_circle_fill : Icons.search,
                  color: suggestion.isLocal ? AppColors.green : AppColors.darkTextDim,
                ),
                title: Text(
                  suggestion.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  suggestion.reason.isEmpty
                      ? suggestion.artist
                      : '${suggestion.artist} · ${suggestion.reason}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: suggestion.isLocal
                    ? const Icon(Icons.play_arrow)
                    : const Icon(Icons.open_in_new, size: 18),
                onTap: () {
                  if (suggestion.isLocal) {
                    final Song? song = library.songById(suggestion.localSongId!);
                    if (song != null) player.playSong(song, context: localSongs);
                  } else {
                    _openUrl(suggestion.searchUrl);
                  }
                },
              );
            }),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                if (localSongs.isNotEmpty) ...<Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => player.setQueue(localSongs),
                      icon: const Icon(Icons.play_arrow),
                      label: Text('Reproducir ${localSongs.length} locales'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final bool ok = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext dialogContext) => AlertDialog(
                              title: const Text('Crear lista'),
                              content: Text(
                                'Se creará "${result.playlistName ?? 'Lista IA'}" con '
                                '${localSongs.length} canciones de tu biblioteca.',
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
                          ) ??
                          false;
                      if (!ok) return;
                      final dynamic playlist = await ai.createPlaylistFromAi(
                        result,
                        fallbackName: 'Lista IA',
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lista "${playlist.name}" creada')),
                      );
                    },
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('Crear lista'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _lastResult = null),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Ocultar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ideaCard(BuildContext context, AiSongIdea idea) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.music_note, color: AppColors.aiCyan),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    idea.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('${idea.genre} · ${idea.mood} · ${idea.bpm} BPM · ${idea.language}'),
            if (idea.structure.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Estructura: ${idea.structure.join(' → ')}'),
              ),
            if (idea.lyricSeed.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(idea.lyricSeed, style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
            const SizedBox(height: 10),
            const Text('Prompt para generador:', style: TextStyle(fontWeight: FontWeight.w600)),
            SelectableText(idea.generatorPrompt, style: const TextStyle(fontSize: 12.5)),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: idea.generatorPrompt));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Prompt copiado')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar prompt'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openUrl(idea.youtubeSearchUrl),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Buscar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Chips con las últimas órdenes que la IA ejecutó sobre la app.
  Widget _executedActions(AiAssistantProvider ai) {
    final List<ActionOutcome> outcomes = ai.lastOutcomes;
    if (outcomes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Órdenes ejecutadas',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: outcomes
                .map(
                  (ActionOutcome outcome) => Chip(
                    avatar: Icon(
                      outcome.ok ? Icons.check_circle : Icons.error_outline,
                      size: 16,
                      color: outcome.ok ? AppColors.green : Theme.of(context).colorScheme.error,
                    ),
                    label: Text(
                      outcome.message,
                      style: const TextStyle(fontSize: 11),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(
    BuildContext context,
    AiAssistantProvider ai,
    LibraryProvider library,
  ) {
    final PlayerProvider player = context.read<PlayerProvider>();
    // Cola DJ infinita: cuando se agotan las canciones encoladas se piden mas
    // (el DJ y la sesion activa deciden cuales). Asi la sesion no se corta.
    player.service.onColaAgotada = (Song actual) async {
      final AiActionResult? mas = await ai.djNext(
        actual,
        player.recentlyPlayed,
        sesion: context.read<SettingsProvider>().sesion,
      );
      if (mas == null) return <Song>[];
      return mas.suggestions
          .map((AiSongSuggestion s) => s.localSongId)
          .whereType<String>()
          .map(library.songById)
          .whereType<Song>()
          .toList();
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: <Widget>[
          // Acceso directo a las canciones en tendencia.
          _action(
            'Sesión: ${context.watch<SettingsProvider>().sesion.isEmpty ? 'ninguna' : context.watch<SettingsProvider>().sesion}',
            Icons.tune,
            () async {
              const List<String> sesiones = <String>[
                '',
                'Fiesta',
                'Relax',
                'Gym',
                'Estudio',
                'Dormir',
              ];
              final SettingsProvider ajustes = context.read<SettingsProvider>();
              final int actual = sesiones.indexOf(ajustes.sesion);
              final String siguiente = sesiones[(actual + 1) % sesiones.length];
              await ajustes.setSesion(siguiente);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    siguiente.isEmpty
                        ? 'Sesión desactivada'
                        : 'Sesión: $siguiente (el DJ y las listas la respetarán)',
                  ),
                ),
              );
            },
          ),
          _action('Mixtape del día', Icons.auto_awesome_motion, () async {
            if (library.songs.isEmpty) return;
            // Lista diaria y estable: la fecha decide el orden, así el mismo día
            // siempre da el mismo mixtape y mañana cambia solo.
            final DateTime hoy = DateTime.now();
            final Random azar =
                Random(hoy.year * 10000 + hoy.month * 100 + hoy.day);
            final List<Song> base = List<Song>.from(library.songs)..shuffle(azar);
            final List<Song> mixtape = <Song>[
              ...base.where((Song s) => s.playCount > 0).take(12),
              ...base.where((Song s) => s.playCount == 0).take(8),
            ];
            if (mixtape.isEmpty) return;
            await player.setQueue(mixtape, startIndex: 0, autoPlay: true);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Mixtape del día: ${mixtape.length} canciones 🎧'),
              ),
            );
          }),
          _action('Tendencias 🔥', Icons.local_fire_department, () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const TrendsScreen()),
            );
          }),
          _action('Recomiéndame', Icons.auto_awesome, () async {
            final AiActionResult? result = await ai.recommend(
              _controller.text.trim().isEmpty
                  ? 'Algo que encaje con lo que suelo escuchar'
                  : _controller.text.trim(),
              currentPlaylist: player.queue.take(10).toList(),
            );
            if (mounted) setState(() => _lastResult = result);
          }),

          _action('Modo DJ', Icons.graphic_eq, () async {
            final Song? current = player.current ?? (library.songs.isNotEmpty ? library.songs.first : null);
            if (current == null) return;
            final AiActionResult? result = await ai.djNext(current, player.recentlyPlayed, sesion: context.read<SettingsProvider>().sesion);
            if (!mounted) return;
            setState(() => _lastResult = result);
          }),
          _action('Crear canción', Icons.music_note, () async {
            final String description = _controller.text.trim().isEmpty
                ? 'Una cumbia alegre sobre Bolivia con sintetizadores'
                : _controller.text.trim();
            final AiSongIdea? idea = await ai.songIdea(description);
            if (mounted) setState(() => _lastIdea = idea);
          }),
        ],
      ),
    );
  }

  Widget _action(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }

  Widget _inputBar(BuildContext context, AiAssistantProvider ai, SettingsProvider settings) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
        child: Row(
          children: <Widget>[
            IconButton(
              tooltip: _listening ? 'Detener dictado' : 'Hablar (español)',
              icon: Icon(_listening ? Icons.mic : Icons.mic_none),
              color: _listening ? AppColors.green : null,
              onPressed: () => _toggleListening(ai, settings),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Pídele música, listas o ideas…',
                ),
                onSubmitted: (String value) => _send(ai, settings),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              tooltip: 'Enviar',
              icon: const Icon(Icons.send),
              onPressed: ai.busy ? null : () => _send(ai, settings),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send(AiAssistantProvider ai, SettingsProvider settings) async {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ai.send(
      text,
      extraContext: settings.autoDj ? 'Modo DJ IA activado.' : null,
      speakReply: settings.ttsEnabled,
    );
    if (settings.ttsEnabled && ai.messages.isNotEmpty) {
      await VoiceService.instance.speak(ai.messages.last.content);
    }
    if (mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Future<void> _toggleListening(AiAssistantProvider ai, SettingsProvider settings) async {
    if (_listening) {
      await VoiceService.instance.stopListening();
      setState(() => _listening = false);
      return;
    }
    final bool ready = await VoiceService.instance.initSpeech(localeId: settings.voiceLocale);
    if (!ready) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dictado no disponible en este dispositivo')),
      );
      return;
    }
    setState(() => _listening = true);
    await VoiceService.instance.startListening(
      localeId: settings.voiceLocale,
      onResult: (String text, bool isFinal) {
        _controller.text = text;
        if (isFinal) {
          setState(() => _listening = false);
          _send(ai, settings);
        }
      },
    );
  }

  Future<void> _testConnection(BuildContext context, AiAssistantProvider ai) async {
    final bool ok = await ai.testConnection();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? ai.status : ai.lastError ?? 'Error de conexión')),
    );
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: url));
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: url));
    }
  }
}

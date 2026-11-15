import '../l10n/app_localizations.dart';
import '../widgets/modern_app_bar.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/motion.dart';
import '../core/soporte.dart';
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
  void initState() {
    super.initState();
    // Primera vez con una clave guardada: se pide el consentimiento antes de
    // que salga ningun dato hacia el proveedor de IA.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final AiAssistantProvider ai = context.read<AiAssistantProvider>();
      if (ai.hasAnyKey && !ai.consentGiven) _asegurarConsentimiento(ai);
    });
  }

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
        title: TituloPantalla(text: AppLocalizations.of(context).aiMusicTitle),
        actions: <Widget>[
          IconButton(
            tooltip: settings.ttsEnabled
                ? AppLocalizations.of(context).aiVoiceOff
                : AppLocalizations.of(context).aiVoiceOn,
            icon: Icon(settings.ttsEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: () => settings.setTtsEnabled(!settings.ttsEnabled),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).clearConversation,
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              final bool ok = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext dialogContext) => AlertDialog(
                      title: Text(AppLocalizations.of(context).clearConversation),
                      content: Text(AppLocalizations.of(context).clearHistoryBody),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                          child: Text(AppLocalizations.of(context).cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                          child: Text(AppLocalizations.of(context).delete),
                        ),
                      ],
                    ),
                  ) ??
                  false;
              if (ok) ai.clearHistory();
            },
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).aiPrivacyMenu,
            icon: const Icon(Icons.privacy_tip_outlined),
            onPressed: () => _mostrarPrivacidad(ai),
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
                    style: TextStyle(fontSize: 12, color: AppColors.darkTextDim),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (ai.hasActiveKey)
                  TextButton.icon(
                    onPressed: () => _testConnection(context, ai),
                    icon: const Icon(Icons.wifi_tethering, size: 16),
                    label: Text(AppLocalizations.of(context).test),
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
                  ai.keyFor(provider) == null ? AppLocalizations.of(context).aiNoKeyBadge(provider.label) : provider.label,
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
      title: AppLocalizations.of(context).aiDjTitle,
      message: AppLocalizations.of(context).aiAskExamples,
      actionLabel: AppLocalizations.of(context).setupApiKeys,
      onAction: () {
        showDialog<void>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: Text(AppLocalizations.of(context).aiProviders),
            content: Text(
              AppLocalizations.of(context).aiKeyMissing,
            ),
            actions: <Widget>[
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(AppLocalizations.of(context).gotIt),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bubble(BuildContext context, AiMessage message, AiAssistantProvider ai) {
    final bool isUser = message.isUser;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations loc = AppLocalizations.of(context);
    final String texto = isUser ? message.content : textoHumano(message.content);
    final Color color = isUser
        ? scheme.primary.withAlpha(46)
        : message.error
            ? scheme.error.withAlpha(38)
            : AppColors.aiViolet.withAlpha(36);
    // Esquina "de la cola" mas cerrada: se lee quien habla sin mirar el texto.
    const Radius grande = Radius.circular(20);
    const Radius cola = Radius.circular(6);
    final BorderRadius forma = BorderRadius.only(
      topLeft: grande,
      topRight: grande,
      bottomLeft: isUser ? grande : cola,
      bottomRight: isUser ? cola : grande,
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.84),
        decoration: BoxDecoration(
          color: color,
          borderRadius: forma,
          border: Border.all(
            color: (isUser ? scheme.primary : AppColors.aiViolet).withAlpha(40),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.smart_toy, size: 15, color: AppColors.aiCyan),
                    const SizedBox(width: 6),
                    Text(
                      message.provider?.label ?? 'IA',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            SelectableText(
              // El texto de la IA se muestra limpio: sin markdown ni bloques
              // internos de órdenes, y con tono de conversación.
              texto,
              style: const TextStyle(fontSize: 14.5, height: 1.35),
            ),
            if (!isUser && !message.error)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      loc.aiGeneratedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5, color: AppColors.darkTextDim),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: loc.aiCopy,
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: texto));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.aiCopied)),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: loc.aiReport,
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    icon: const Icon(Icons.outlined_flag_rounded),
                    onPressed: () => _reportar(message, texto),
                  ),
                ],
              )
            else
              const SizedBox(height: 4),
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
                Icon(Icons.auto_awesome, size: 18, color: AppColors.aiCyan),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.playlistName ?? AppLocalizations.of(context).aiRecommendations,
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
                  style: TextStyle(fontSize: 12.5, color: AppColors.darkTextDim),
                ),
              ),
            const SizedBox(height: 10),
            ..._sugerenciasUnicas(result.suggestions).take(30).map((AiSongSuggestion suggestion) {
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
                trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: suggestion.isLocal
                              ? AppColors.green.withAlpha(34)
                              : AppColors.aiCyan.withAlpha(28),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: suggestion.isLocal
                                ? AppColors.green
                                : AppColors.aiCyan,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          suggestion.isLocal
                              ? AppLocalizations.of(context).aiBadgeLibrary
                              : AppLocalizations.of(context).aiBadgeExternal,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: suggestion.isLocal
                                ? AppColors.green
                                : AppColors.aiCyan,
                          ),
                        ),
                      ),
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
                      label: Text(AppLocalizations.of(context).aiPlayLocal(localSongs.length)),
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
                              title: Text(AppLocalizations.of(context).createList),
                              content: Text(
                                '${AppLocalizations.of(context).playlistWillBe(result.playlistName ?? 'IA')} '
                                '${AppLocalizations.of(context).songsFromLibrary(localSongs.length)}',
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(false),
                                  child: Text(AppLocalizations.of(context).cancel),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(true),
                                  child: Text(AppLocalizations.of(context).create),
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
                        SnackBar(content: Text(AppLocalizations.of(context).listCreated(playlist.name))),
                      );
                    },
                    icon: const Icon(Icons.playlist_add),
                    label: Text(AppLocalizations.of(context).createList),
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
                label: Text(AppLocalizations.of(context).aiHide),
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
                Icon(Icons.music_note, color: AppColors.aiCyan),
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
                child: Text('${AppLocalizations.of(context).aiStructure}: ${idea.structure.join(' → ')}'),
              ),
            if (idea.lyricSeed.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(idea.lyricSeed, style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).aiGeneratedLabel,
                      style: TextStyle(fontSize: 10.5, color: AppColors.darkTextDim),
                    ),
                  ),
                  IconButton(
                    tooltip: AppLocalizations.of(context).aiReport,
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    icon: const Icon(Icons.outlined_flag_rounded),
                    onPressed: () => _reportar(
                      null,
                      '${idea.title}\n${idea.lyricSeed}\n${idea.generatorPrompt}',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(AppLocalizations.of(context).promptForGenerator, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                        SnackBar(content: Text(AppLocalizations.of(context).promptCopied)),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: Text(AppLocalizations.of(context).copyPrompt),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openUrl(idea.youtubeSearchUrl),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(AppLocalizations.of(context).tabSearch),
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
          Text(
            AppLocalizations.of(context).actionsRun,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
    final SettingsProvider ajustesDj = context.read<SettingsProvider>();
    // Cola DJ infinita: cuando se agotan las canciones encoladas se piden mas
    // (el DJ y la sesion activa deciden cuales). Asi la sesion no se corta.
    player.service.onColaAgotada = (Song actual) async {
      // Sin consentimiento la cola no pide nada a la IA.
      if (!ai.consentGiven) return <Song>[];
      final AiActionResult? mas = await ai.djNext(
        actual,
        player.recentlyPlayed,
        sesion: ajustesDj.sesion,
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
            AppLocalizations.of(context).sessionLabel(_nombreSesion(context, _normalizarSesion(context.watch<SettingsProvider>().sesion))),
            Icons.tune,
            () async {
              const List<String> sesiones = <String>[
                '',
                'fiesta',
                'relax',
                'gym',
                'estudio',
                'dormir',
              ];
              final SettingsProvider ajustes = context.read<SettingsProvider>();
              final int actual = sesiones.indexOf(_normalizarSesion(ajustes.sesion));
              final String siguiente = sesiones[(actual + 1) % sesiones.length];
              await ajustes.setSesion(siguiente);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    siguiente.isEmpty
                        ? AppLocalizations.of(context).sessionDisabled
                        : AppLocalizations.of(context).sessionNotice(_nombreSesion(context, siguiente)),
                  ),
                ),
              );
            },
          ),
          _action(AppLocalizations.of(context).mixtapeOfDay, Icons.auto_awesome_motion, () async {
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
                content: Text(AppLocalizations.of(context).mixtapeToday(mixtape.length)),
              ),
            );
          }),
          _action('${AppLocalizations.of(context).trendsTitle} 🔥', Icons.local_fire_department, () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const TrendsScreen()),
            );
          }),
          _action(AppLocalizations.of(context).recommendMe, Icons.auto_awesome, () async {
            if (!await _asegurarConsentimiento(ai)) return;
            final AiActionResult? result = await ai.recommend(
              _controller.text.trim().isEmpty
                  ? 'Algo que encaje con lo que suelo escuchar'
                  : _controller.text.trim(),
              currentPlaylist: player.queue.take(10).toList(),
            );
            if (mounted) setState(() => _lastResult = result);
          }),

          _action(AppLocalizations.of(context).aiDj, Icons.graphic_eq, () async {
            final Song? current = player.current ?? (library.songs.isNotEmpty ? library.songs.first : null);
            if (current == null) return;
            if (!await _asegurarConsentimiento(ai)) return;
            if (!context.mounted) return;
            final AiActionResult? result = await ai.djNext(current, player.recentlyPlayed, sesion: context.read<SettingsProvider>().sesion);
            if (!mounted) return;
            setState(() => _lastResult = result);
          }),
          _action(AppLocalizations.of(context).createSong, Icons.music_note, () async {
            final String description = _controller.text.trim().isEmpty
                ? 'Una cumbia alegre sobre Bolivia con sintetizadores'
                : _controller.text.trim();
            if (!await _asegurarConsentimiento(ai)) return;
            final AiSongIdea? idea = await ai.songIdea(description);
            if (mounted) setState(() => _lastIdea = idea);
          }),
        ],
      ),
    );
  }

  /// Token interno de la sesion (independiente del idioma).
  String _normalizarSesion(String valor) {
    final String v = valor.trim().toLowerCase();
    const Map<String, String> equivalencias = <String, String>{
      'fiesta': 'fiesta',
      'party': 'fiesta',
      'relax': 'relax',
      'gym': 'gym',
      'estudio': 'estudio',
      'study': 'estudio',
      'dormir': 'dormir',
      'sleep': 'dormir',
    };
    return equivalencias[v] ?? (v.isEmpty ? '' : v);
  }

  /// Nombre traducido de una sesion.
  String _nombreSesion(BuildContext context, String token) {
    final AppLocalizations loc = AppLocalizations.of(context);
    switch (token) {
      case 'fiesta':
        return loc.sessionFiesta;
      case 'relax':
        return loc.sessionRelax;
      case 'gym':
        return loc.sessionGym;
      case 'estudio':
        return loc.sessionStudy;
      case 'dormir':
        return loc.sessionSleep;
      default:
        return loc.sessionNone;
    }
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
            // El dictado no viene en esta compilacion: sin boton que no hace nada.
            if (VoiceService.instance.isSpeechAvailable)
              IconButton(
                tooltip: _listening ? 'Detener dictado' : 'Hablar (español)',
                icon: Icon(_listening ? Icons.mic : Icons.mic_none),
                color: _listening ? AppColors.green : null,
                onPressed: () => _toggleListening(ai, settings),
              )
            else
              const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).askHint,
                ),
                onSubmitted: (String value) => _send(ai, settings),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              tooltip: AppLocalizations.of(context).aiSend,
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
    if (ai.hasActiveKey && !await _asegurarConsentimiento(ai)) return;
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
        SnackBar(content: Text(AppLocalizations.of(context).dictationUnavailable)),
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
      SnackBar(content: Text(ok ? ai.status : ai.lastError ?? AppLocalizations.of(context).aiConnectionError)),
    );
  }

  /// Muestra el aviso de privacidad de la IA y guarda la respuesta.
  /// Devuelve true si el usuario ya habia aceptado o acepta ahora.
  Future<bool> _asegurarConsentimiento(AiAssistantProvider ai) async {
    if (ai.consentGiven) return true;
    final AppLocalizations loc = AppLocalizations.of(context);
    final bool acepta = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            icon: Icon(Icons.privacy_tip_outlined, color: AppColors.aiCyan),
            title: Text(loc.aiConsentTitle),
            content: SingleChildScrollView(child: Text(loc.aiConsentBody)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(loc.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(loc.aiConsentAccept),
              ),
            ],
          ),
        ) ??
        false;
    if (acepta) await ai.setConsent(true);
    return acepta;
  }

  /// Menu "Privacidad de la IA": volver a leer el aviso o retirar el permiso.
  Future<void> _mostrarPrivacidad(AiAssistantProvider ai) async {
    if (!ai.consentGiven) {
      await _asegurarConsentimiento(ai);
      return;
    }
    final AppLocalizations loc = AppLocalizations.of(context);
    final bool retirar = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            icon: Icon(Icons.privacy_tip_outlined, color: AppColors.aiCyan),
            title: Text(loc.aiPrivacyMenu),
            content: SingleChildScrollView(child: Text(loc.aiConsentBody)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(loc.aiConsentRevoke),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(loc.gotIt),
              ),
            ],
          ),
        ) ??
        false;
    if (retirar) await ai.setConsent(false);
  }

  /// Reportar una respuesta de la IA (requisito de Google Play para apps con
  /// IA generativa): abre el correo con la respuesta; si no hay app de correo,
  /// la copia al portapapeles.
  Future<void> _reportar(AiMessage? message, String texto) async {
    Hapticos.toque();
    final AppLocalizations loc = AppLocalizations.of(context);
    final String proveedor = message?.provider?.label ?? '';
    final String cuerpo = 'Proveedor: $proveedor\n'
        'Fecha: ${message?.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String()}\n\n'
        '--- Respuesta reportada ---\n$texto';
    final Uri correo = Uri(
      scheme: 'mailto',
      path: Soporte.email,
      query: 'subject=${Uri.encodeComponent('BotMp3 - Reporte de respuesta de IA')}'
          '&body=${Uri.encodeComponent(cuerpo)}',
    );
    bool abierto = false;
    try {
      abierto = await launchUrl(correo, mode: LaunchMode.externalApplication);
    } catch (_) {
      abierto = false;
    }
    if (!abierto) await Clipboard.setData(ClipboardData(text: cuerpo));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(abierto ? loc.aiReportThanks : loc.aiReportCopied)),
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

/// Quita duplicados de las sugerencias de la IA (misma cancion y artista).
List<AiSongSuggestion> _sugerenciasUnicas(List<AiSongSuggestion> lista) {
  final Set<String> vistos = <String>{};
  return lista.where((AiSongSuggestion s) {
    final String clave =
        '${s.title.toLowerCase().trim()}|${s.artist.toLowerCase().trim()}';
    return vistos.add(clave);
  }).toList();
}

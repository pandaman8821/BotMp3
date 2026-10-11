import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/ai_models.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/ai/ai_client.dart';
import '../services/ai/action_executor.dart';
import '../services/ai/ai_actions.dart';
import '../services/ai/ai_bridge.dart';
import '../services/ai/ai_orchestrator.dart';
import '../services/secure_keys_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import 'library_provider.dart';
import 'player_provider.dart';
import 'settings_provider.dart';

/// Estado del agente musical: claves por proveedor, historial de conversación,
/// acciones (recomendar, generar listas, DJ IA, buscar, crear canciones).
class AiAssistantProvider extends ChangeNotifier {
  AiAssistantProvider({required LibraryProvider library}) : _library = library;

  final LibraryProvider _library;
  final SecureKeysService _secure = SecureKeysService.instance;
  final StorageService _storage = StorageService.instance;

  final Map<AiProvider, String> _keys = <AiProvider, String>{};
  final List<AiMessage> _messages = <AiMessage>[];

  SettingsService? _settings;
  bool _busy = false;
  String? _lastError;
  String _status = 'Listo';

  /// Últimas órdenes ejecutadas (se muestran en la pantalla de IA).
  List<ActionOutcome> _lastOutcomes = <ActionOutcome>[];
  bool _executing = false;

  List<AiMessage> get messages => List<AiMessage>.unmodifiable(_messages);
  bool get busy => _busy;
  String? get lastError => _lastError;
  String get status => _status;
  List<ActionOutcome> get lastOutcomes => List<ActionOutcome>.unmodifiable(_lastOutcomes);
  bool get executing => _executing;

  AiProvider get activeProvider => _settings?.preferredProvider ?? AiProvider.deepseek;
  String get activeModel =>
      _settings?.modelFor(activeProvider) ?? activeProvider.defaultModel;

  bool get hasAnyKey => _keys.values.any((String key) => key.trim().isNotEmpty);
  bool get hasActiveKey => (_keys[activeProvider] ?? '').trim().isNotEmpty;

  String? keyFor(AiProvider provider) => _keys[provider];

  // ------------------------------------------------------------------ ciclo

  Future<void> init(SettingsService settings) async {
    _settings = settings;
    _keys.clear();
    for (final AiProvider provider in AiProvider.values) {
      final String? key = await _secure.readKey(provider);
      if (key != null) _keys[provider] = key;
    }
    await _loadHistory();
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    final List<dynamic>? raw = await _storage.readJsonList(StorageKeys.aiChat);
    if (raw == null) return;
    _messages
      ..clear()
      ..addAll(
        raw.whereType<Map<String, dynamic>>().map(AiMessage.fromJson),
      );
  }

  Future<void> _persistHistory() async {
    await _storage.writeJson(
      StorageKeys.aiChat,
      _messages.map((AiMessage message) => message.toJson()).toList(),
    );
  }

  // ------------------------------------------------------------------ claves

  Future<void> saveKey(AiProvider provider, String key) async {
    await _secure.writeKey(provider, key);
    if (key.trim().isEmpty) {
      _keys.remove(provider);
    } else {
      _keys[provider] = key.trim();
    }
    notifyListeners();
  }

  Future<void> deleteKey(AiProvider provider) async {
    await _secure.deleteKey(provider);
    _keys.remove(provider);
    notifyListeners();
  }

  String maskFor(AiProvider provider) {
    final String? key = _keys[provider];
    if (key == null || key.isEmpty) return '';
    return SecureKeysService.mask(key);
  }

  // ------------------------------------------------------------------ ajustes IA

  Future<void> selectProvider(AiProvider provider) async {
    final SettingsService? settings = _settings;
    if (settings == null) return;
    await settings.setPreferredProvider(provider);
    notifyListeners();
  }

  Future<void> selectModel(AiProvider provider, String model) async {
    final SettingsService? settings = _settings;
    if (settings == null) return;
    await settings.setModelFor(provider, model);
    notifyListeners();
  }

  AiOrchestrator? buildOrchestrator() {
    final String key = (_keys[activeProvider] ?? '').trim();
    if (key.isEmpty) {
      _lastError = 'Falta la API key de ${activeProvider.label}.';
      return null;
    }
    return AiOrchestrator(
      client: createAiClient(
        provider: activeProvider,
        apiKey: key,
        model: activeModel,
      ),
      librarySongs: _library.songs,
    );
  }

  /// Comprueba que la clave funciona y devuelve true si responde.
  Future<bool> testConnection() async {
    final AiOrchestrator? orchestrator = buildOrchestrator();
    if (orchestrator == null) {
      _lastError = 'Configura primero una API key en Ajustes de IA.';
      notifyListeners();
      return false;
    }
    _setBusy(true, 'Probando ${activeProvider.label}…');
    try {
      final String reply = await orchestrator.testConnection();
      _status = reply.isEmpty ? 'Conexión correcta' : reply;
      _lastError = null;
      return true;
    } catch (error) {
      _lastError = error is AiRequestException ? error.message : error.toString();
      _status = 'Error de conexión';
      return false;
    } finally {
      _setBusy(false, _status);
    }
  }

  // ------------------------------------------------------------------ chat

  Future<void> send(
    String text, {
    String? extraContext,
    bool speakReply = false,
  }) async {
    final String clean = text.trim();
    if (clean.isEmpty) return;

    final AiOrchestrator? orchestrator = buildOrchestrator();
    if (orchestrator == null) {
      _messages.add(
        AiMessage(
          role: 'assistant',
          content: _lastError ?? 'Configura una API key para hablar conmigo.',
          createdAt: DateTime.now(),
          error: true,
        ),
      );
      notifyListeners();
      return;
    }

    _messages.add(
      AiMessage(role: 'user', content: clean, createdAt: DateTime.now()),
    );
    _setBusy(true, '${activeProvider.label} está pensando…');
    await _persistHistory();

    try {
      final List<AiMessage> history = _messages
          .where((AiMessage message) => !message.error)
          .toList()
          .reversed
          .take(16)
          .toList()
          .reversed
          .toList();
      final String reply = await orchestrator.chat(history, extraContext: extraContext);
      _messages.add(
        AiMessage(
          role: 'assistant',
          content: reply,
          provider: activeProvider,
          model: activeModel,
          createdAt: DateTime.now(),
        ),
      );
      _lastError = null;
      await _executeFromReply(reply, clean);
    } catch (error) {
      final String message =
          error is AiRequestException ? error.message : 'Error inesperado: $error';
      _lastError = message;
      _messages.add(
        AiMessage(
          role: 'assistant',
          content: message,
          provider: activeProvider,
          model: activeModel,
          createdAt: DateTime.now(),
          error: true,
        ),
      );
    } finally {
      await _persistHistory();
      _setBusy(false, 'Listo');
    }
  }

  // ------------------------------------------------------------------ acciones IA

  // ------------------------------------------------------- motor de acciones

  /// Ejecuta las órdenes que la IA incluyó en su respuesta y, si no hay
  /// ninguna, interpreta el mensaje del usuario con las reglas locales.
  Future<void> _executeFromReply(String reply, String userText) async {
    final (String _, List<AiAction> fromAi) = AiActionParser.fromAiReply(reply);
    final List<AiAction> actions = fromAi.isNotEmpty
        ? fromAi
        : AiActionParser.fromNaturalLanguage(userText);
    if (actions.isEmpty) return;
    await _runActions(actions);
  }

  /// Ejecuta una orden escrita en la barra de comandos ("hazlo ya").
  Future<List<ActionOutcome>> runCommand(String text) async {
    List<AiAction> actions = AiActionParser.fromNaturalLanguage(text);
    if (actions.isEmpty) {
      final AiOrchestrator? orchestrator = buildOrchestrator();
      if (orchestrator != null) {
        try {
          final String reply = await orchestrator.chat(<AiMessage>[
            AiMessage(
              role: 'user',
              content: 'Ordena la ejecución de: $text',
              createdAt: DateTime.now(),
            ),
          ]);
          final (String _, List<AiAction> fromAi) = AiActionParser.fromAiReply(reply);
          actions = fromAi;
        } catch (error) {
          _lastError = error is AiRequestException ? error.message : error.toString();
        }
      }
    }
    if (actions.isEmpty) {
      _lastOutcomes = <ActionOutcome>[
        const ActionOutcome(
          AiAction(AiActionType.help),
          'No entendí la orden. Escribe «ayuda» para ver ejemplos.',
          ok: false,
        ),
      ];
      notifyListeners();
      return _lastOutcomes;
    }
    return _runActions(actions);
  }

  Future<List<ActionOutcome>> _runActions(List<AiAction> actions) async {
    final PlayerProvider? player = AiBridge.player;
    final SettingsProvider? settings = AiBridge.settings;
    if (player == null || settings == null) return <ActionOutcome>[];

    _executing = true;
    notifyListeners();
    final ActionExecutor executor = ActionExecutor(
      library: _library,
      player: player,
      settings: settings,
    );
    try {
      final List<ActionOutcome> outcomes = await executor.runAll(actions);
      _lastOutcomes = outcomes
          .where((ActionOutcome outcome) => outcome.message.isNotEmpty)
          .toList();
      if (_lastOutcomes.isNotEmpty) {
        _messages.add(
          AiMessage(
            role: 'assistant',
            content: '⚡ ${_lastOutcomes.map((ActionOutcome o) => o.message).join("\n")}',
            provider: activeProvider,
            createdAt: DateTime.now(),
          ),
        );
        await _persistHistory();
      }
      return _lastOutcomes;
    } finally {
      _executing = false;
      notifyListeners();
    }
  }

  /// Pide a la IA metadatos corregidos para el editor simplificado.
  Future<Map<String, String>?> suggestMetadata(Song song) async {
    final AiOrchestrator? orchestrator = buildOrchestrator();
    if (orchestrator == null) return null;
    _setBusy(true, 'Completando los datos de la canción…');
    try {
      return await orchestrator.suggestMetadata(song);
    } catch (error) {
      _lastError = error is AiRequestException ? error.message : error.toString();
      return null;
    } finally {
      _setBusy(false, 'Listo');
    }
  }

  /// Recomendaciones personalizadas según género, artista, mood o lista actual.
  Future<AiActionResult?> recommend(
    String request, {
    List<Song> currentPlaylist = const <Song>[],
    int count = 10,
  }) async {
    return _runAction(
      loadingLabel: 'Buscando recomendaciones…',
      action: (AiOrchestrator orchestrator) =>
          orchestrator.recommend(request: request, currentPlaylist: currentPlaylist, count: count),
      registerInChat: true,
    );
  }

  /// Genera una lista de reproducción completa a partir de una petición.
  Future<AiActionResult?> generatePlaylist(String request, {int count = 30}) async {
    return _runAction(
      loadingLabel: 'Creando lista de $count canciones…',
      action: (AiOrchestrator orchestrator) =>
          orchestrator.generatePlaylist(request: request, count: count),
      registerInChat: true,
    );
  }

  /// Búsqueda inteligente con explicación en lenguaje natural.
  Future<AiActionResult?> smartSearch(String query) async {
    return _runAction(
      loadingLabel: 'Interpretando tu búsqueda…',
      action: (AiOrchestrator orchestrator) => orchestrator.smartSearch(query),
      registerInChat: false,
    );
  }

  /// Modo DJ IA: elige la siguiente canción y la explica.
  Future<AiActionResult?> djNext(Song current, List<Song> recent) async {
    return _runAction(
      loadingLabel: 'El DJ está eligiendo…',
      action: (AiOrchestrator orchestrator) =>
          orchestrator.djNext(current: current, recentlyPlayed: recent),
      registerInChat: false,
    );
  }

  /// Idea de canción nueva (letra + prompt para generadores).
  Future<AiSongIdea?> songIdea(String description) async {
    final AiOrchestrator? orchestrator = buildOrchestrator();
    if (orchestrator == null) {
      notifyListeners();
      return null;
    }
    _setBusy(true, 'Componiendo una idea…');
    try {
      final AiSongIdea idea = await orchestrator.songIdea(description);
      _messages.add(
        AiMessage(
          role: 'assistant',
          content: '🎼 Idea creada: **${idea.title}** (${idea.genre}, ${idea.bpm} BPM)\n\n'
              '${idea.lyricSeed}\n\nPrompt para generador:\n`${idea.generatorPrompt}`',
          provider: activeProvider,
          model: activeModel,
          createdAt: DateTime.now(),
        ),
      );
      await _persistHistory();
      return idea;
    } catch (error) {
      _lastError = error is AiRequestException ? error.message : error.toString();
      return null;
    } finally {
      _setBusy(false, 'Listo');
    }
  }

  /// Crea una lista local a partir del resultado de la IA y devuelve la lista.
  Future<Playlist> createPlaylistFromAi(
    AiActionResult result, {
    required String fallbackName,
    String? prompt,
  }) async {
    final List<String> songIds = result.suggestions
        .map((AiSongSuggestion suggestion) => suggestion.localSongId)
        .whereType<String>()
        .toList();
    return _library.createPlaylist(
      name: result.playlistName ?? fallbackName,
      description: result.playlistDescription ?? 'Generada por IA',
      songIds: songIds,
      isAiGenerated: true,
      aiPrompt: prompt,
    );
  }

  Future<AiActionResult?> _runAction({
    required String loadingLabel,
    required Future<AiActionResult> Function(AiOrchestrator orchestrator) action,
    required bool registerInChat,
  }) async {
    final AiOrchestrator? orchestrator = buildOrchestrator();
    if (orchestrator == null) {
      notifyListeners();
      return null;
    }

    _setBusy(true, loadingLabel);
    try {
      final AiActionResult result = await action(orchestrator);
      if (registerInChat) {
        _messages.add(
          AiMessage(
            role: 'assistant',
            content: result.text,
            provider: activeProvider,
            model: activeModel,
            createdAt: DateTime.now(),
            suggestedSongIds: result.suggestions
                .map((AiSongSuggestion s) => s.localSongId ?? '')
                .where((String id) => id.isNotEmpty)
                .toList(),
          ),
        );
        await _persistHistory();
      }
      _lastError = null;
      return result;
    } catch (error) {
      _lastError = error is AiRequestException ? error.message : error.toString();
      return null;
    } finally {
      _setBusy(false, 'Listo');
    }
  }

  void clearHistory() {
    _messages.clear();
    _persistHistory();
    notifyListeners();
  }

  /// Exporta la conversación como texto legible.
  String exportConversation() {
    final StringBuffer buffer = StringBuffer('Conversación BotMp3 IA\n\n');
    for (final AiMessage message in _messages) {
      buffer.writeln('${message.isUser ? 'Yo' : 'IA'}: ${message.content}\n');
    }
    return buffer.toString();
  }

  /// Texto compacto de la conversación reciente (contexto para la IA).
  String recentContext({int turns = 6}) {
    final List<AiMessage> recent = _messages.length <= turns
        ? _messages
        : _messages.sublist(_messages.length - turns);
    return recent
        .map((AiMessage message) => '${message.isUser ? 'Usuario' : 'IA'}: ${message.content}')
        .join('\n');
  }

  void _setBusy(bool value, String status) {
    _busy = value;
    _status = status;
    notifyListeners();
  }

  /// Guarda el historial en un JSON exportable.
  String exportHistoryJson() =>
      jsonEncode(_messages.map((AiMessage message) => message.toJson()).toList());
}

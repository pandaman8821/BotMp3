import '../core/ui_strings.dart';
import '../services/ai/model_catalog.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/fila_tareas.dart';
import '../core/text_utils.dart';

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

  // ------------------------------------------------------- orden del chat
  //
  // Cada petición del chat RESERVA su turno al pulsarla (mensaje del usuario
  // + hueco "pensando…") y se ejecuta en una fila, de una en una. Así, aunque
  // se pidan varias cosas seguidas, cada respuesta aparece justo debajo de lo
  // que la provocó y en el orden en que se pidió (antes cada respuesta se
  // añadía al final cuando llegaba y el chat se mezclaba).

  final FilaDeTareas _fila = FilaDeTareas();
  int _secuencia = 0;
  final Map<String, AiActionResult> _resultados = <String, AiActionResult>{};
  final Map<String, AiSongIdea> _ideas = <String, AiSongIdea>{};

  /// Tarjeta de recomendaciones asociada a un mensaje (si la hay).
  AiActionResult? resultadoDe(String? id) => id == null ? null : _resultados[id];

  /// Idea de canción asociada a un mensaje (si la hay).
  AiSongIdea? ideaDe(String? id) => id == null ? null : _ideas[id];

  void ocultarResultado(String id) {
    if (_resultados.remove(id) != null) notifyListeners();
  }

  String _nuevoId() => 'm${DateTime.now().microsecondsSinceEpoch}_${_secuencia++}';

  /// Ejecuta [tarea] cuando hayan terminado todas las anteriores del chat.
  Future<T> _enFila<T>(Future<T> Function() tarea) => _fila.agregar<T>(tarea);

  /// Añade lo que pidió el usuario y un hueco para la respuesta. Devuelve el
  /// id del hueco.
  String _reservarTurno(String peticion, AiProvider proveedor, String modelo) {
    _messages.add(
      AiMessage(id: _nuevoId(), role: 'user', content: peticion, createdAt: DateTime.now()),
    );
    final String hueco = _nuevoId();
    _messages.add(
      AiMessage(
        id: hueco,
        role: 'assistant',
        content: '',
        provider: proveedor,
        model: modelo,
        createdAt: DateTime.now(),
        pending: true,
      ),
    );
    notifyListeners();
    return hueco;
  }

  /// Pone la respuesta en su hueco. Devuelve false si ya no existe (el usuario
  /// borró la conversación mientras se esperaba).
  bool _completarTurno(String hueco, AiMessage respuesta) {
    final int i = _messages.indexWhere((AiMessage m) => m.id == hueco);
    if (i < 0) return false;
    _messages[i] = respuesta.copyWith(id: hueco, pending: false);
    notifyListeners();
    return true;
  }

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
        raw
            .whereType<Map<String, dynamic>>()
            .map(AiMessage.fromJson)
            // Historiales antiguos no tenían id: se les asigna uno.
            .map((AiMessage m) => m.id == null ? m.copyWith(id: _nuevoId()) : m),
      );
  }

  Future<void> _persistHistory() async {
    await _storage.writeJson(
      StorageKeys.aiChat,
      _messages
          .where((AiMessage message) => !message.pending)
          .map((AiMessage message) => message.toJson())
          .toList(),
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

  /// true cuando el usuario ya aceptó el aviso de privacidad de la IA.
  bool get consentGiven => _settings?.aiConsent ?? false;

  Future<void> setConsent(bool value) async {
    final SettingsService? settings = _settings;
    if (settings == null) return;
    await settings.setAiConsent(value);
    notifyListeners();
  }

  AiOrchestrator? buildOrchestrator() {
    // Sin consentimiento no sale ningún dato hacia el proveedor de IA.
    if (!consentGiven) {
      _lastError = UiStrings.loc.aiConsentRequired;
      return null;
    }
    final String key = (_keys[activeProvider] ?? '').trim();
    if (key.isEmpty) {
      _lastError = UiStrings.loc.aiMissingKey(activeProvider.label);
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
      if (consentGiven) _lastError = UiStrings.loc.aiKeyMissingFirst;
      notifyListeners();
      return false;
    }
    _setBusy(true, UiStrings.loc.aiTesting(activeProvider.label));
    try {
      final String reply = await orchestrator.testConnection();
      // Conexion valida: se descarga el catalogo REAL de modelos para que el
      // selector ofrezca solo los que existen hoy (nunca mas caducados).
      final String? claveModelos = await _secure.readKey(activeProvider);
      if (claveModelos != null) {
        await ModelCatalog.actualizar(activeProvider, claveModelos);
      }
      _status = reply.isEmpty ? UiStrings.loc.aiConnectionOk : reply;
      _lastError = null;
      return true;
    } catch (error) {
      _lastError = error is AiRequestException ? error.message : error.toString();
      _status = UiStrings.loc.aiErrorConnection;
      return false;
    } finally {
      _setBusy(false, _status);
    }
  }

  // ------------------------------------------------------------------ chat

  /// Envía un mensaje al chat. Devuelve el texto de la respuesta (o null).
  Future<String?> send(
    String text, {
    String? extraContext,
    bool speakReply = false,
  }) async {
    final String clean = text.trim();
    if (clean.isEmpty) return null;

    final AiOrchestrator? orchestrator = buildOrchestrator();
    if (orchestrator == null) {
      _messages.add(
        AiMessage(
          id: _nuevoId(),
          role: 'assistant',
          content: _lastError ?? UiStrings.loc.aiNeedKey,
          createdAt: DateTime.now(),
          error: true,
        ),
      );
      notifyListeners();
      return null;
    }

    final AiProvider proveedor = activeProvider;
    final String modelo = activeModel;
    // El turno se reserva YA, en el orden en que el usuario escribe.
    final String hueco = _reservarTurno(clean, proveedor, modelo);
    await _persistHistory();

    return _enFila<String?>(() async {
      _setBusy(true, UiStrings.loc.aiThinking(proveedor.label));
      try {
        // Contexto: solo lo que había ANTES de esta pregunta (no las
        // preguntas que se escribieron después y aún esperan turno).
        final int posicion = _messages.indexWhere((AiMessage m) => m.id == hueco);
        final List<AiMessage> previos = (posicion < 0 ? _messages : _messages.sublist(0, posicion))
            .where((AiMessage message) => !message.error && !message.pending)
            .toList();
        final List<AiMessage> history =
            previos.length <= 16 ? previos : previos.sublist(previos.length - 16);
        final String reply = await orchestrator.chat(history, extraContext: extraContext);
        final bool colocada = _completarTurno(
          hueco,
          AiMessage(
            role: 'assistant',
            content: reply,
            provider: proveedor,
            model: modelo,
            createdAt: DateTime.now(),
          ),
        );
        if (!colocada) return null;
        _lastError = null;
        await _executeFromReply(reply, clean, despuesDe: hueco);
        return reply;
      } catch (error) {
        final String message = error is AiRequestException
            ? error.message
            : UiStrings.loc.aiUnexpectedError('$error');
        _lastError = message;
        _completarTurno(
          hueco,
          AiMessage(
            role: 'assistant',
            content: message,
            provider: proveedor,
            model: modelo,
            createdAt: DateTime.now(),
            error: true,
          ),
        );
        return null;
      } finally {
        await _persistHistory();
        _setBusy(false, 'Listo');
      }
    });
  }

  // ------------------------------------------------------------------ acciones IA

  // ------------------------------------------------------- motor de acciones

  /// Ejecuta las órdenes que la IA incluyó en su respuesta y, si no hay
  /// ninguna, interpreta el mensaje del usuario con las reglas locales.
  Future<void> _executeFromReply(String reply, String userText, {String? despuesDe}) async {
    final (String _, List<AiAction> fromAi) = AiActionParser.fromAiReply(reply);
    final List<AiAction> actions = fromAi.isNotEmpty
        ? fromAi
        : AiActionParser.fromNaturalLanguage(userText);
    if (actions.isEmpty) return;
    await _runActions(actions, despuesDe: despuesDe);
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
              content: 'Executing: $text',
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
        ActionOutcome(
          const AiAction(AiActionType.help),
          UiStrings.loc.aiUnknownCommand,
          ok: false,
        ),
      ];
      notifyListeners();
      return _lastOutcomes;
    }
    return _runActions(actions);
  }

  /// Ejecuta las órdenes. El resumen "⚡" se coloca justo después del mensaje
  /// [despuesDe] (la respuesta que las pidió), no al final del chat.
  Future<List<ActionOutcome>> _runActions(List<AiAction> actions, {String? despuesDe}) async {
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
        final AiMessage resumen = AiMessage(
          id: _nuevoId(),
          role: 'assistant',
          content: '⚡ ${_lastOutcomes.map((ActionOutcome o) => o.message).join("\n")}',
          provider: activeProvider,
          createdAt: DateTime.now(),
        );
        final int origen = despuesDe == null
            ? -1
            : _messages.indexWhere((AiMessage m) => m.id == despuesDe);
        if (origen >= 0) {
          _messages.insert(origen + 1, resumen);
        } else {
          _messages.add(resumen);
        }
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
    _setBusy(true, UiStrings.loc.aiCompletingMetadata);
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
  ///
  /// [peticion] es lo que se muestra en el chat como mensaje del usuario.
  Future<AiActionResult?> recommend(
    String request, {
    List<Song> currentPlaylist = const <Song>[],
    int count = 10,
    String? peticion,
  }) async {
    return _runAction(
      loadingLabel: UiStrings.loc.aiLookingRecs,
      action: (AiOrchestrator orchestrator) =>
          orchestrator.recommend(request: request, currentPlaylist: currentPlaylist, count: count),
      registerInChat: true,
      peticion: peticion ?? request,
    );
  }

  /// Genera una lista de reproducción completa a partir de una petición.
  Future<AiActionResult?> generatePlaylist(String request, {int count = 30, String? peticion}) async {
    return _runAction(
      loadingLabel: UiStrings.loc.aiCreatingPlaylist(count),
      action: (AiOrchestrator orchestrator) =>
          orchestrator.generatePlaylist(request: request, count: count),
      registerInChat: true,
      peticion: peticion ?? request,
    );
  }

  /// Búsqueda inteligente con explicación en lenguaje natural.
  Future<AiActionResult?> smartSearch(String query) async {
    return _runAction(
      loadingLabel: UiStrings.loc.aiInterpretingSearch,
      action: (AiOrchestrator orchestrator) => orchestrator.smartSearch(query),
      registerInChat: false,
    );
  }

  /// Modo DJ IA: elige la siguiente canción y la explica.
  ///
  /// Desde el reproductor o la cola infinita no escribe en el chat; desde el
  /// chat ([peticion] no nulo) reserva su turno como cualquier otra petición.
  Future<AiActionResult?> djNext(
    Song current,
    List<Song> recent, {
    String sesion = '',
    String? peticion,
  }) async {
    return _runAction(
      loadingLabel: UiStrings.loc.aiDjChoosing,
      action: (AiOrchestrator orchestrator) async {
        final AiActionResult r =
            await orchestrator.djNext(current: current, recentlyPlayed: recent, sesion: sesion);
        // La tarjeta del chat se titula "Modo DJ" (antes salía como
        // "Recomendaciones", igual que la función Recomiéndame).
        return r.playlistName != null
            ? r
            : AiActionResult(
                text: r.text,
                suggestions: r.suggestions,
                playlistName: UiStrings.loc.djModeTitle,
                playlistDescription: r.playlistDescription,
              );
      },
      registerInChat: peticion != null,
      peticion: peticion,
      // En segundo plano (reproductor, cola infinita) no enciende la barra de
      // "pensando" del chat ni pisa el último error de otras funciones.
      silencioso: peticion == null,
    );
  }

  /// Idea de canción nueva (letra + prompt para generadores).
  Future<AiSongIdea?> songIdea(String description, {String? peticion}) async {
    final AiOrchestrator? orchestrator = buildOrchestrator();
    if (orchestrator == null) {
      notifyListeners();
      return null;
    }
    final AiProvider proveedor = activeProvider;
    final String modelo = activeModel;
    final String hueco = _reservarTurno(peticion ?? description, proveedor, modelo);
    return _enFila<AiSongIdea?>(() async {
      _setBusy(true, UiStrings.loc.aiComposingIdea);
      try {
        final AiSongIdea idea = await orchestrator.songIdea(description);
        final bool colocada = _completarTurno(
          hueco,
          AiMessage(
            role: 'assistant',
            content: '${UiStrings.loc.aiIdeaCreated(idea.title, idea.genre, idea.bpm)}\n\n'
                '${idea.lyricSeed}\n\n${UiStrings.loc.aiGeneratorPrompt}:\n`${idea.generatorPrompt}`',
            provider: proveedor,
            model: modelo,
            createdAt: DateTime.now(),
          ),
        );
        if (colocada) _ideas[hueco] = idea;
        return idea;
      } catch (error) {
        _lastError = error is AiRequestException ? error.message : error.toString();
        _completarTurno(hueco, _mensajeDeError(_lastError!, proveedor, modelo));
        return null;
      } finally {
        await _persistHistory();
        _setBusy(false, 'Listo');
      }
    });
  }

  AiMessage _mensajeDeError(String texto, AiProvider proveedor, String modelo) => AiMessage(
        role: 'assistant',
        content: texto,
        provider: proveedor,
        model: modelo,
        createdAt: DateTime.now(),
        error: true,
      );

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
      description: result.playlistDescription ?? UiStrings.loc.aiGeneratedPlaylist,
      songIds: songIds,
      isAiGenerated: true,
      aiPrompt: prompt,
    );
  }

  Future<AiActionResult?> _runAction({
    required String loadingLabel,
    required Future<AiActionResult> Function(AiOrchestrator orchestrator) action,
    required bool registerInChat,
    String? peticion,
    bool silencioso = false,
  }) async {
    final AiOrchestrator? orchestrator = buildOrchestrator();
    if (orchestrator == null) {
      notifyListeners();
      return null;
    }

    // Fuera del chat (búsqueda, DJ del reproductor, cola infinita): se ejecuta
    // al momento y no toca la conversación.
    if (!registerInChat) {
      if (silencioso) {
        try {
          return await action(orchestrator);
        } catch (error) {
          debugPrint('DJ en segundo plano: $error');
          return null;
        }
      }
      _setBusy(true, loadingLabel);
      try {
        final AiActionResult result = await action(orchestrator);
        _lastError = null;
        return result;
      } catch (error) {
        _lastError = error is AiRequestException ? error.message : error.toString();
        return null;
      } finally {
        _setBusy(false, 'Listo');
      }
    }

    final AiProvider proveedor = activeProvider;
    final String modelo = activeModel;
    final String hueco = _reservarTurno(peticion ?? loadingLabel, proveedor, modelo);
    return _enFila<AiActionResult?>(() async {
      _setBusy(true, loadingLabel);
      try {
        final AiActionResult result = await action(orchestrator);
        final bool colocada = _completarTurno(
          hueco,
          AiMessage(
            role: 'assistant',
            // Se guarda ya limpio: frase natural, nunca JSON.
            content: textoParaChat(result.text),
            provider: proveedor,
            model: modelo,
            createdAt: DateTime.now(),
            suggestedSongIds: result.suggestions
                .map((AiSongSuggestion s) => s.localSongId ?? '')
                .where((String id) => id.isNotEmpty)
                .toList(),
          ),
        );
        // La tarjeta va pegada a SU mensaje, no al final del chat.
        if (colocada) _resultados[hueco] = result;
        _lastError = null;
        return result;
      } catch (error) {
        _lastError = error is AiRequestException ? error.message : error.toString();
        _completarTurno(hueco, _mensajeDeError(_lastError!, proveedor, modelo));
        return null;
      } finally {
        await _persistHistory();
        _setBusy(false, 'Listo');
      }
    });
  }

  void clearHistory() {
    _messages.clear();
    _resultados.clear();
    _ideas.clear();
    _persistHistory();
    notifyListeners();
  }

  /// Exporta la conversación como texto legible.
  String exportConversation() {
    final StringBuffer buffer = StringBuffer('${UiStrings.loc.chatExportHeader}\n\n');
    for (final AiMessage message in _messages.where((AiMessage m) => !m.pending)) {
      buffer.writeln('${message.isUser ? UiStrings.loc.chatMe : UiStrings.loc.chatAi}: ${message.content}\n');
    }
    return buffer.toString();
  }

  /// Texto compacto de la conversación reciente (contexto para la IA).
  String recentContext({int turns = 6}) {
    final List<AiMessage> listos = _messages.where((AiMessage m) => !m.pending).toList();
    final List<AiMessage> recent =
        listos.length <= turns ? listos : listos.sublist(listos.length - turns);
    return recent
        .map((AiMessage message) => '${message.isUser ? 'Usuario' : 'IA'}: ${message.content}')
        .join('\n');
  }

  /// Tareas de IA en curso. Las del chat van en fila, pero la cola DJ, la
  /// búsqueda y los metadatos corren en paralelo: con un simple booleano, la
  /// primera que terminaba apagaba el indicador de las demás.
  int _tareasActivas = 0;

  void _setBusy(bool value, String status) {
    if (value) {
      _tareasActivas++;
      _status = status;
    } else {
      _tareasActivas = _tareasActivas > 0 ? _tareasActivas - 1 : 0;
      if (_tareasActivas == 0) _status = status;
    }
    _busy = _tareasActivas > 0;
    notifyListeners();
  }

  /// Guarda el historial en un JSON exportable.
  String exportHistoryJson() =>
      jsonEncode(_messages
          .where((AiMessage message) => !message.pending)
          .map((AiMessage message) => message.toJson())
          .toList());
}

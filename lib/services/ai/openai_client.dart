part of 'ai_client.dart';

/// Cliente compatible con el formato OpenAI Chat Completions.
/// Lo usan tanto OpenAI como DeepSeek (mismo contrato de API).
class OpenAiCompatibleClient extends AiClient {
  OpenAiCompatibleClient({
    required super.apiKey,
    required super.model,
    required this.baseUrl,
    required this.providerKind,
    super.httpClient,
  });

  final String baseUrl;
  final AiProvider providerKind;

  @override
  AiProvider get provider => providerKind;

  @override
  Future<String> complete(
    List<AiMessage> messages, {
    String? systemPrompt,
    bool json = false,
    double temperature = 0.7,
    int maxTokens = 1800,
  }) async {
    // Los modelos de razonamiento (o1 / deepseek-reasoner) no aceptan
    // temperature ni el rol "system": se adapta la petición.
    final bool reasoningModel = model.startsWith('o1') || model.contains('reasoner');

    final List<Map<String, String>> payloadMessages = <Map<String, String>>[];
    if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
      if (reasoningModel) {
        payloadMessages.add(<String, String>{
          'role': 'user',
          'content': 'Instrucciones del sistema:\n$systemPrompt',
        });
      } else {
        payloadMessages.add(<String, String>{'role': 'system', 'content': systemPrompt});
      }
    }
    for (final AiMessage message in messages) {
      payloadMessages.add(<String, String>{
        'role': message.role == 'assistant' ? 'assistant' : 'user',
        'content': message.content,
      });
    }

    // La API de DeepSeek activa el modo «thinking» por defecto. En las tareas
    // con salida JSON (metadatos, listas, búsqueda, órdenes) se desactiva:
    // responde antes, cuesta menos y no arriesga el formato. En conversación
    // se deja activado para ganar calidad.
    final bool esDeepSeek = baseUrl.contains('deepseek');

    final Map<String, dynamic> body = <String, dynamic>{
      'model': model,
      'messages': payloadMessages,
      if (!reasoningModel) 'temperature': temperature,
      'max_tokens': maxTokens,
      if (json && !reasoningModel)
        'response_format': <String, String>{'type': 'json_object'},
      if (esDeepSeek)
        'thinking': <String, String>{'type': json ? 'disabled' : 'enabled'},
    };

    final Map<String, dynamic> response = await postJson(
      Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions'),
      body,
      headers: <String, String>{'Authorization': 'Bearer $apiKey'},
    );

    final List<dynamic>? choices = response['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw AiRequestException('${provider.label} no devolvió ninguna respuesta');
    }
    final Map<String, dynamic> first = choices.first as Map<String, dynamic>;
    final Map<String, dynamic>? message = first['message'] as Map<String, dynamic>?;
    final String content = (message?['content'] ?? '').toString().trim();
    if (content.isEmpty) {
      throw AiRequestException('${provider.label} devolvió una respuesta vacía');
    }
    return content;
  }
}

/// OpenAI (GPT-4o, o1…).
class OpenAiClient extends OpenAiCompatibleClient {
  OpenAiClient({required super.apiKey, required super.model, super.httpClient})
      : super(
          baseUrl: 'https://api.openai.com/v1',
          providerKind: AiProvider.openai,
        );
}

/// DeepSeek (DeepSeek-V3 `deepseek-chat` / DeepSeek-R1 `deepseek-reasoner`).
class DeepSeekClient extends OpenAiCompatibleClient {
  DeepSeekClient({required super.apiKey, required super.model, super.httpClient})
      : super(
          baseUrl: 'https://api.deepseek.com',
          providerKind: AiProvider.deepseek,
        );
}

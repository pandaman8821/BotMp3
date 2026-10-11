part of 'ai_client.dart';

/// Anthropic Claude (3.5 Sonnet / 3 Opus…) vía Messages API.
class ClaudeClient extends AiClient {
  ClaudeClient({required super.apiKey, required super.model, super.httpClient});

  @override
  AiProvider get provider => AiProvider.claude;

  @override
  Future<String> complete(
    List<AiMessage> messages, {
    String? systemPrompt,
    bool json = false,
    double temperature = 0.7,
    int maxTokens = 1800,
  }) async {
    final List<Map<String, String>> payload = <Map<String, String>>[];
    for (final AiMessage message in messages) {
      payload.add(<String, String>{
        'role': message.role == 'assistant' ? 'assistant' : 'user',
        'content': json && message == messages.last
            ? '${message.content}\n\nResponde ÚNICAMENTE con JSON válido, sin markdown.'
            : message.content,
      });
    }

    final Map<String, dynamic> body = <String, dynamic>{
      'model': model,
      'max_tokens': maxTokens,
      'temperature': temperature,
      if (systemPrompt != null && systemPrompt.trim().isNotEmpty) 'system': systemPrompt,
      'messages': payload,
    };

    final Map<String, dynamic> response = await postJson(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      body,
      headers: <String, String>{
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
    );

    final List<dynamic>? blocks = response['content'] as List<dynamic>?;
    final String text = (blocks ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .where((Map<String, dynamic> block) => block['type'] == 'text')
        .map((Map<String, dynamic> block) => (block['text'] ?? '').toString())
        .join('\n')
        .trim();

    if (text.isEmpty) {
      throw AiRequestException('Claude devolvió una respuesta vacía');
    }
    return text;
  }
}

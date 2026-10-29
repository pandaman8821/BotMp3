part of 'ai_client.dart';

/// Google Gemini (1.5 Pro / 1.5 Flash / 2.0 Flash) vía Generative Language API.
class GeminiClient extends AiClient {
  GeminiClient({required super.apiKey, required super.model, super.httpClient});

  @override
  AiProvider get provider => AiProvider.gemini;

  @override
  Future<String> complete(
    List<AiMessage> messages, {
    String? systemPrompt,
    bool json = false,
    double temperature = 0.7,
    int maxTokens = 1800,
  }) async {
    final List<Map<String, dynamic>> contents = <Map<String, dynamic>>[];
    for (final AiMessage message in messages) {
      contents.add(<String, dynamic>{
        'role': message.role == 'assistant' ? 'model' : 'user',
        'parts': <Map<String, String>>[
          <String, String>{'text': message.content},
        ],
      });
    }

    final Map<String, dynamic> body = <String, dynamic>{
      if (systemPrompt != null && systemPrompt.trim().isNotEmpty)
        'system_instruction': <String, dynamic>{
          'parts': <Map<String, String>>[
            <String, String>{'text': systemPrompt},
          ],
        },
      'contents': contents,
      'generationConfig': <String, dynamic>{
        'temperature': temperature,
        'maxOutputTokens': maxTokens,
        if (json) 'responseMimeType': 'application/json',
            // Los modelos 2.5 piensan por defecto: se comen los tokens y la
            // respuesta sale vacia o cortada. Se desactiva el pensamiento.
            if (model.contains('2.5'))
              'thinkingConfig': <String, dynamic>{'thinkingBudget': 0},
      },
    };

    final Uri uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
    ).replace(queryParameters: <String, String>{'key': apiKey});

    final Map<String, dynamic> response = await postJson(uri, body);

    final List<dynamic>? candidates = response['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw AiRequestException('Gemini no devolvió ninguna respuesta');
    }
    final Map<String, dynamic> candidate = candidates.first as Map<String, dynamic>;
    final Map<String, dynamic>? content = candidate['content'] as Map<String, dynamic>?;
    final List<dynamic>? parts = content?['parts'] as List<dynamic>?;
    final String text = (parts ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .where((Map<String, dynamic> part) => part['thought'] != true)
            .map((Map<String, dynamic> part) => (part['text'] ?? '').toString())
        .join('\n')
        .trim();

    if (text.isEmpty) {
      throw AiRequestException('Gemini devolvió una respuesta vacía');
    }
    return text;
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants.dart';
import '../../models/ai_models.dart';

// Implementaciones por proveedor (misma librería para compartir utilidades).
part 'claude_client.dart';
part 'gemini_client.dart';
part 'openai_client.dart';

/// Error controlado de una API de IA con mensaje ya traducido para el usuario.
class AiRequestException implements Exception {
  AiRequestException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Cliente común para todos los proveedores de IA.
abstract class AiClient {
  AiClient({
    required this.apiKey,
    required this.model,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 90),
  }) : _http = httpClient ?? http.Client();

  final String apiKey;
  final String model;
  final Duration timeout;
  final http.Client _http;

  AiProvider get provider;

  /// Envía la conversación y devuelve el texto de la respuesta.
  Future<String> complete(
    List<AiMessage> messages, {
    String? systemPrompt,
    bool json = false,
    double temperature = 0.7,
    int maxTokens = 1800,
  });

  void dispose() => _http.close();

  // ------------------------------------------------------------------ utilidades

  /// POST con manejo de errores homogéneo (401, 402, 429, 5xx…).
  Future<Map<String, dynamic>> postJson(
    Uri uri,
    Map<String, dynamic> body, {
    Map<String, String> headers = const <String, String>{},
  }) async {
    http.Response response;
    try {
      response = await _http
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json; charset=utf-8',
              ...headers,
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } catch (error) {
      throw AiRequestException('Sin conexión con ${provider.label} ($error)');
    }

    final String raw = response.body;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        throw AiRequestException('Respuesta inesperada de ${provider.label}');
      } on FormatException {
        throw AiRequestException('${provider.label} devolvió una respuesta no válida');
      }
    }

    throw AiRequestException(
      _translateError(response.statusCode, raw),
      statusCode: response.statusCode,
    );
  }

  String _translateError(int status, String raw) {
    final String detail = _extractApiMessage(raw);
    switch (status) {
      case 400:
        return 'Solicitud rechazada por ${provider.label}: $detail';
      case 401:
      case 403:
        return 'API key de ${provider.label} inválida o sin permisos.';
      case 402:
        return 'Saldo insuficiente en ${provider.label}. Recarga tu cuenta.';
      case 404:
        return 'Modelo "$model" no disponible en ${provider.label}.';
      case 429:
        return 'Demasiadas peticiones a ${provider.label}. Espera unos segundos.';
      default:
        return 'Error ${status} de ${provider.label}: $detail';
    }
  }

  String _extractApiMessage(String raw) {
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final dynamic error = decoded['error'];
        if (error is Map<String, dynamic>) {
          return (error['message'] ?? error['status'] ?? '').toString();
        }
        if (error != null) return error.toString();
        if (decoded['message'] != null) return decoded['message'].toString();
      }
    } catch (_) {}
    return raw.length > 180 ? '${raw.substring(0, 180)}…' : raw;
  }
}

/// Extrae el primer bloque JSON equilibrado de un texto (los modelos suelen
/// envolverlo en ```json ... ``` o añadir comentarios).
String? extractJsonBlock(String raw) {
  final String text = raw
      .replaceAll('```json', '```')
      .replaceAll('```JSON', '```')
      .trim();
  final int startBrace = text.indexOf('{');
  final int startBracket = text.indexOf('[');

  int start;
  int open;
  int close;
  if (startBrace >= 0 && (startBracket < 0 || startBrace < startBracket)) {
    start = startBrace;
    open = '{'.codeUnitAt(0);
    close = '}'.codeUnitAt(0);
  } else if (startBracket >= 0) {
    start = startBracket;
    open = '['.codeUnitAt(0);
    close = ']'.codeUnitAt(0);
  } else {
    return null;
  }

  int depth = 0;
  bool inString = false;
  bool escaped = false;
  for (int i = start; i < text.length; i++) {
    final int code = text.codeUnitAt(i);
    if (escaped) {
      escaped = false;
      continue;
    }
    if (code == '\\'.codeUnitAt(0)) {
      escaped = true;
      continue;
    }
    if (code == '"'.codeUnitAt(0)) {
      inString = !inString;
      continue;
    }
    if (inString) continue;
    if (code == open) depth++;
    if (code == close) {
      depth--;
      if (depth == 0) return text.substring(start, i + 1);
    }
  }
  return null;
}

/// Construye el cliente adecuado para el proveedor elegido.
AiClient createAiClient({
  required AiProvider provider,
  required String apiKey,
  required String model,
  http.Client? httpClient,
}) {
  switch (provider) {
    case AiProvider.openai:
      return OpenAiClient(apiKey: apiKey, model: model, httpClient: httpClient);
    case AiProvider.deepseek:
      return DeepSeekClient(apiKey: apiKey, model: model, httpClient: httpClient);
    case AiProvider.gemini:
      return GeminiClient(apiKey: apiKey, model: model, httpClient: httpClient);
    case AiProvider.claude:
      return ClaudeClient(apiKey: apiKey, model: model, httpClient: httpClient);
  }
}

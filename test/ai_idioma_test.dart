import 'package:botmp3/core/constants.dart';
import 'package:botmp3/models/ai_models.dart';
import 'package:botmp3/services/ai/ai_client.dart';
import 'package:botmp3/services/ai/ai_orchestrator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Cliente falso que guarda el systemPrompt que recibe la IA.
class _ClienteEspia extends AiClient {
  _ClienteEspia() : super(apiKey: 'x', model: 'x');

  String? ultimoSystem;

  @override
  AiProvider get provider => AiProvider.deepseek;

  @override
  Future<String> complete(
    List<AiMessage> messages, {
    String? systemPrompt,
    bool json = false,
    double temperature = 0.7,
    int maxTokens = 1800,
  }) async {
    ultimoSystem = systemPrompt;
    return 'ok';
  }
}

void main() {
  tearDown(() => Intl.defaultLocale = null);

  Future<String> systemDelChat(String locale) async {
    Intl.defaultLocale = locale;
    final _ClienteEspia cliente = _ClienteEspia();
    await AiOrchestrator(client: cliente, librarySongs: const [])
        .chat(<AiMessage>[const AiMessage(role: 'user', content: 'Hello')]);
    return cliente.ultimoSystem!;
  }

  test('la IA ya no esta obligada a responder siempre en espanol', () async {
    final String system = await systemDelChat('en');
    expect(system.contains('SIEMPRE en español'), isFalse);
    expect(system, contains('mismo idioma en que te escribe el usuario'));
  });

  test('las plantillas en espanol no fuerzan el idioma de las tareas automaticas', () async {
    final String system = await systemDelChat('ja');
    expect(system, contains('NO indican el idioma del usuario'));
    expect(system, contains('si no hay texto suyo, usa Japanese'));
  });

  test('el idioma de respaldo es el de la app', () async {
    expect(await systemDelChat('en'), contains('idioma de la app: English'));
    expect(await systemDelChat('es'), contains('idioma de la app: Spanish'));
    expect(await systemDelChat('pt_BR'), contains('idioma de la app: Portuguese'));
  });
}

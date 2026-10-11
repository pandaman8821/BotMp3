import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Voz en español de BotMp3.
///
/// * **TTS (respuestas habladas): activo.** Usa el motor de voz del sistema
///   (`flutter_tts`), sin código nativo ni NDK.
/// * **Dictado (speech-to-text): PUNTO DE EXTENSIÓN.** Esta compilación no
///   incluye `speech_to_text` porque su dependencia `jni` compila código nativo
///   y obliga a instalar el NDK (~1 GB) y CMake. Los métodos de dictado
///   mantienen su firma y devuelven "no disponible" para que la interfaz siga
///   funcionando; para activarlos:
///
///   1. `flutter pub add speech_to_text`
///   2. `sdkmanager "ndk;27.0.12077973" "cmake;3.22.1"`
///   3. Restaurar el reconocedor en los métodos `initSpeech`, `startListening`
///      y `stopListening` (ver PUNTO DE EXTENSIÓN).
class VoiceService {
  VoiceService._();

  static final VoiceService instance = VoiceService._();

  FlutterTts? _tts;
  bool _listening = false;

  /// El dictado no está incluido en esta versión (ver nota de la clase).
  bool get isListening => _listening;

  bool get isSpeechAvailable => false;

  /// PUNTO DE EXTENSIÓN (dictado): devuelve siempre false en esta compilación.
  Future<bool> initSpeech({String localeId = 'es_ES'}) async {
    debugPrint('Dictado no incluido en esta compilación (requiere speech_to_text + NDK).');
    return false;
  }

  /// PUNTO DE EXTENSIÓN (dictado): sin motor de reconocimiento no hace nada.
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    String localeId = 'es_ES',
  }) async {
    _listening = false;
    onResult('', true);
  }

  Future<void> stopListening() async {
    _listening = false;
  }

  /// Lee un texto en voz alta (por ejemplo, las recomendaciones del DJ IA).
  Future<void> speak(String text, {String locale = 'es-ES'}) async {
    if (text.trim().isEmpty) return;
    try {
      final FlutterTts tts = _tts ??= FlutterTts();
      await tts.setLanguage(locale);
      await tts.setSpeechRate(0.5);
      await tts.setPitch(1.0);
      await tts.awaitSpeakCompletion(true);
      await tts.speak(text);
    } catch (error) {
      debugPrint('TTS no disponible: $error');
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  Future<List<String>> availableLanguages() async {
    try {
      final FlutterTts tts = _tts ??= FlutterTts();
      final dynamic languages = await tts.getLanguages;
      if (languages is List) {
        return languages.map((dynamic value) => value.toString()).toList();
      }
    } catch (_) {}
    return <String>['es-ES', 'es-MX', 'es-AR', 'es-BO'];
  }
}

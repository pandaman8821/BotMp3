import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';

import '../core/fila_tareas.dart';
import '../core/text_utils.dart';
import 'settings_service.dart';

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

  /// Las frases se dicen de una en una: si el chat y el DJ hablan a la vez,
  /// la segunda espera a que termine la primera (antes la cortaba).
  final FilaDeTareas _turnos = FilaDeTareas();

  /// Lee un texto en voz alta (por ejemplo, las recomendaciones del DJ IA).
  ///
  /// El texto se limpia antes (nunca se lee JSON ni markdown) y, si no se
  /// indica [locale], se usa el idioma activo de la app.
  Future<void> speak(String text, {String? locale}) {
    final String limpio = textoParaChat(text);
    if (limpio.trim().isEmpty) return Future<void>.value();
    return _turnos.agregar<void>(() async {
      try {
        final FlutterTts tts = _tts ??= FlutterTts();
        await tts.setLanguage(locale ?? _idiomaVoz());
        await tts.setSpeechRate(0.5);
        await tts.setPitch(1.0);
        await tts.awaitSpeakCompletion(true);
        await tts.speak(limpio);
      } catch (error) {
        debugPrint('TTS no disponible: $error');
      }
    });
  }

  /// Etiqueta de voz (p. ej. "pt-BR") para el idioma activo de la app. Si el
  /// usuario eligió en Ajustes una voz de ese mismo idioma (p. ej. es-MX), se
  /// respeta; si no, se usa la variante habitual del idioma de la app.
  static String _idiomaVoz() {
    final String app = (Intl.defaultLocale ?? 'es').replaceAll('_', '-').split('-').first;
    final String? elegida = SettingsService.actual?.voiceLocale;
    if (elegida != null && elegida.toLowerCase().startsWith(app.toLowerCase())) {
      return elegida;
    }
    return _idiomaApp();
  }

  static String _idiomaApp() {
    const Map<String, String> region = <String, String>{
      'es': 'es-ES',
      'en': 'en-US',
      'pt': 'pt-BR',
      'de': 'de-DE',
      'fr': 'fr-FR',
      'it': 'it-IT',
      'ja': 'ja-JP',
      'ko': 'ko-KR',
      'zh': 'zh-CN',
      'hi': 'hi-IN',
    };
    final List<String> partes =
        (Intl.defaultLocale ?? 'es').replaceAll('_', '-').split('-');
    if (partes.length > 1 && partes[1].isNotEmpty) return '${partes[0]}-${partes[1]}';
    return region[partes[0]] ?? 'es-ES';
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

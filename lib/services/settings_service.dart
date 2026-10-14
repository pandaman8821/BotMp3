import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

/// Modos de repetición del reproductor.
enum RepeatMode { off, all, one }

/// Ajustes persistentes de BotMp3 (SharedPreferences).
class SettingsService {
  SettingsService._(this._prefs);

  static SettingsService? _instance;

  /// Instancia ya creada (consulta síncrona). La usan servicios que no
  /// pueden esperar a `instance()`.
  static SettingsService? get actual => _instance;

  static Future<SettingsService> instance() async {
    final SettingsService? cached = _instance;
    if (cached != null) return cached;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final SettingsService created = SettingsService._(prefs);
    _instance = created;
    return created;
  }

  final SharedPreferences _prefs;

  // ------------------------------------------------------------------ tema
  /// País de las listas de tendencias (código de tienda: es, mx, us…).
  String get trendsCountry => _prefs.getString('trends_country') ?? 'es';

  Future<void> setTrendsCountry(String value) async {
    await _prefs.setString('trends_country', value);
  }

  /// Aviso diario con las canciones en tendencia.
  bool get trendsNotify => _prefs.getBool('trends_notify') ?? false;

  Future<void> setTrendsNotify(bool value) async {
    await _prefs.setBool('trends_notify', value);
  }

  /// Hora del aviso diario (0-23).
  int get trendsHour => _prefs.getInt('trends_hour') ?? 20;

  Future<void> setTrendsHour(int value) async {
    await _prefs.setInt('trends_hour', value);
  }

  /// Efecto cristal (Liquid Glass) en barras y paneles.
  bool get glassEnabled => _prefs.getBool('glass_enabled') ?? true;

  Future<void> setGlassEnabled(bool value) async {
    await _prefs.setBool('glass_enabled', value);
  }

  /// Intensidad del cristal (0.2 sutil · 1.0 máximo).
  double get glassIntensity => _prefs.getDouble('glass_intensity') ?? 0.75;

  Future<void> setGlassIntensity(double value) async {
    await _prefs.setDouble('glass_intensity', value);
  }

  /// Importa automáticamente la música del dispositivo al abrir la app.
  bool get autoImport => _prefs.getBool('auto_import') ?? true;

  Future<void> setAutoImport(bool value) async {
    await _prefs.setBool('auto_import', value);
  }

  /// Importar también audios de apps (WhatsApp, Telegram…) y notas de voz.
  /// Desactivado (por defecto) solo se importa música.
  bool get importMediaAudio => _prefs.getBool('import_media_audio') ?? false;

  Future<void> setImportMediaAudio(bool value) async {
    await _prefs.setBool('import_media_audio', value);
  }

  /// Ajuste de volumen por canción (id -> factor 0.5..2.0): iguala las pistas
  /// que suenan mucho más flojas o más fuertes que el resto.
  double factorVolumen(String songId) {
    final num? v = _mapaVolumen()[songId] as num?;
    return v == null ? 1.0 : v.toDouble().clamp(0.5, 2.0);
  }

  Future<void> setFactorVolumen(String songId, double factor) async {
    final Map<String, dynamic> mapa = _mapaVolumen();
    if ((factor - 1.0).abs() < 0.01) {
      mapa.remove(songId);
    } else {
      mapa[songId] = double.parse(factor.clamp(0.5, 2.0).toStringAsFixed(2));
    }
    await _prefs.setString('volumen_canciones', jsonEncode(mapa));
  }

  Map<String, dynamic> _mapaVolumen() {
    try {
      final String? raw = _prefs.getString('volumen_canciones');
      if (raw == null || raw.isEmpty) return <String, dynamic>{};
      final dynamic decoded = jsonDecode(raw);
      return decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
  /// Sesión de escucha activa (Fiesta, Relax, Gym, Estudio, Dormir).
  /// Cadena vacía = sin sesión.
  String get sesion => _prefs.getString('sesion_escucha') ?? '';

  Future<void> setSesion(String value) async {
    await _prefs.setString('sesion_escucha', value);
  }

  ThemeMode get themeMode {
    switch (_prefs.getString('theme_mode') ?? 'system') {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString('theme_mode', mode.name);

  // ------------------------------------------------------------------ audio
  AiProvider get preferredProvider {
    final String? raw = _prefs.getString('ai_provider');
    return AiProvider.values.firstWhere(
      (AiProvider p) => p.id == raw,
      orElse: () => AiProvider.deepseek,
    );
  }

  Future<void> setPreferredProvider(AiProvider provider) =>
      _prefs.setString('ai_provider', provider.id);

  /// Nombres de modelo retirados por los proveedores → sustituto vigente.
  static const Map<String, String> _modelosRetirados = <String, String>{
    'deepseek-chat': 'deepseek-flash',
    'deepseek-reasoner': 'deepseek-v4-pro',
  };

  String modelFor(AiProvider provider) {
    final String? guardado = _prefs.getString('ai_model_${provider.id}');
    if (guardado == null || guardado.trim().isEmpty) return provider.defaultModel;
    // Si el proveedor retiró ese modelo, se migra solo al equivalente actual.
    return _modelosRetirados[guardado.trim()] ?? guardado.trim();
  }

  Future<void> setModelFor(AiProvider provider, String model) =>
      _prefs.setString('ai_model_${provider.id}', model);

  bool get autoDj => _prefs.getBool('ai_auto_dj') ?? false;
  Future<void> setAutoDj(bool value) => _prefs.setBool('ai_auto_dj', value);

  // ------------------------------------------------------------- reproductor
  bool get shuffle => _prefs.getBool('player_shuffle') ?? false;
  Future<void> setShuffle(bool value) => _prefs.setBool('player_shuffle', value);

  RepeatMode get repeatMode {
    final String raw = _prefs.getString('player_repeat') ?? 'off';
    return RepeatMode.values.firstWhere(
      (RepeatMode m) => m.name == raw,
      orElse: () => RepeatMode.off,
    );
  }

  Future<void> setRepeatMode(RepeatMode mode) =>
      _prefs.setString('player_repeat', mode.name);

  double get volume => _prefs.getDouble('player_volume') ?? 1.0;
  Future<void> setVolume(double value) => _prefs.setDouble('player_volume', value);

  bool get keepScreenOn => _prefs.getBool('player_keep_screen_on') ?? true;
  Future<void> setKeepScreenOn(bool value) =>
      _prefs.setBool('player_keep_screen_on', value);

  bool get showWaveAnimation => _prefs.getBool('player_wave') ?? true;
  Future<void> setShowWaveAnimation(bool value) =>
      _prefs.setBool('player_wave', value);

  // --------------------------------------------------------------- rendimiento
  /// Modo ahorro: menos animaciones y refresco de progreso más lento.
  /// Pensado para reproducción continua y temperaturas extremas.
  bool get batterySaver => _prefs.getBool('battery_saver') ?? false;
  Future<void> setBatterySaver(bool value) =>
      _prefs.setBool('battery_saver', value);

  bool get thermalGuard => _prefs.getBool('thermal_guard') ?? true;
  Future<void> setThermalGuard(bool value) =>
      _prefs.setBool('thermal_guard', value);

  // -------------------------------------------------------------------- voz
  bool get voiceEnabled => _prefs.getBool('voice_enabled') ?? true;
  Future<void> setVoiceEnabled(bool value) =>
      _prefs.setBool('voice_enabled', value);

  bool get ttsEnabled => _prefs.getBool('tts_enabled') ?? false;
  Future<void> setTtsEnabled(bool value) => _prefs.setBool('tts_enabled', value);

  String get voiceLocale => _prefs.getString('voice_locale') ?? 'es-ES';
  Future<void> setVoiceLocale(String value) =>
      _prefs.setString('voice_locale', value);

  // ------------------------------------------------------------------- varios
  bool get hasSeenIntro => _prefs.getBool('seen_intro') ?? false;
  Future<void> setHasSeenIntro(bool value) => _prefs.setBool('seen_intro', value);

  Future<void> resetAll() async {
    await _prefs.clear();
  }
}

import 'package:flutter/material.dart' hide RepeatMode;

import '../core/constants.dart';
import '../services/ai/ai_bridge.dart';
import '../widgets/glass.dart';
import '../services/settings_service.dart';

/// Ajustes de la app expuestos a la interfaz.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._service) {
    AiBridge.settings = this;
  }

  final SettingsService _service;

  SettingsService get service => _service;

  ThemeMode get themeMode => _service.themeMode;
  bool get autoImport => _service.autoImport;

  /// Incluir audios de apps de mensajería y notas de voz.
  bool get importMediaAudio => _service.importMediaAudio;

  Future<void> setImportMediaAudio(bool value) async {
    await _service.setImportMediaAudio(value);
    notifyListeners();
  }

  /// Sesión de escucha activa (Fiesta, Relax, Gym, Estudio, Dormir).
  String get sesion => _service.sesion;

  Future<void> setSesion(String value) async {
    await _service.setSesion(value);
    notifyListeners();
  }
  bool get glassEnabled => _service.glassEnabled;
  String get trendsCountry => _service.trendsCountry;
  bool get trendsNotify => _service.trendsNotify;
  int get trendsHour => _service.trendsHour;

  Future<void> setTrendsCountry(String value) async {
    await _service.setTrendsCountry(value);
    notifyListeners();
  }

  Future<void> setTrendsNotify(bool value) async {
    await _service.setTrendsNotify(value);
    notifyListeners();
  }

  Future<void> setTrendsHour(int value) async {
    await _service.setTrendsHour(value);
    notifyListeners();
  }
  double get glassIntensity => _service.glassIntensity;

  /// El cristal se desactiva con el ahorro de batería.
  bool get glassActive => _service.glassEnabled && !_service.batterySaver;

  /// Calidad efectiva del cristal según los ajustes.
  GlassQuality get glassQuality =>
      glassQualityFor(enabled: glassActive, intensity: _service.glassIntensity);

  Future<void> setGlassEnabled(bool value) async {
    await _service.setGlassEnabled(value);
    notifyListeners();
  }

  Future<void> setGlassIntensity(double value) async {
    await _service.setGlassIntensity(value);
    notifyListeners();
  }
  AiProvider get preferredProvider => _service.preferredProvider;
  String modelFor(AiProvider provider) => _service.modelFor(provider);
  bool get autoDj => _service.autoDj;
  bool get shuffle => _service.shuffle;
  RepeatMode get repeatMode => _service.repeatMode;
  double get volume => _service.volume;
  bool get keepScreenOn => _service.keepScreenOn;
  bool get showWaveAnimation => _service.showWaveAnimation;
  bool get batterySaver => _service.batterySaver;
  bool get thermalGuard => _service.thermalGuard;
  bool get voiceEnabled => _service.voiceEnabled;
  bool get ttsEnabled => _service.ttsEnabled;
  String get voiceLocale => _service.voiceLocale;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _service.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setAutoImport(bool value) async {
    await _service.setAutoImport(value);
    notifyListeners();
  }

  Future<void> setPreferredProvider(AiProvider provider) async {
    await _service.setPreferredProvider(provider);
    notifyListeners();
  }

  Future<void> setModelFor(AiProvider provider, String model) async {
    await _service.setModelFor(provider, model);
    notifyListeners();
  }

  Future<void> setAutoDj(bool value) async {
    await _service.setAutoDj(value);
    notifyListeners();
  }

  Future<void> setShowWaveAnimation(bool value) async {
    await _service.setShowWaveAnimation(value);
    notifyListeners();
  }

  Future<void> setBatterySaver(bool value) async {
    await _service.setBatterySaver(value);
    notifyListeners();
  }

  Future<void> setThermalGuard(bool value) async {
    await _service.setThermalGuard(value);
    notifyListeners();
  }

  Future<void> setKeepScreenOn(bool value) async {
    await _service.setKeepScreenOn(value);
    notifyListeners();
  }

  Future<void> setVoiceEnabled(bool value) async {
    await _service.setVoiceEnabled(value);
    notifyListeners();
  }

  Future<void> setTtsEnabled(bool value) async {
    await _service.setTtsEnabled(value);
    notifyListeners();
  }

  Future<void> setVoiceLocale(String value) async {
    await _service.setVoiceLocale(value);
    notifyListeners();
  }
}

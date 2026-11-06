import 'package:flutter/services.dart';

/// Puente con Android para saber cuando se conecta/desconecta un dispositivo
/// de audio (auriculares, Bluetooth, AUX). Permite reanudar la musica sola.
class AudioDeviceWatcher {
  const AudioDeviceWatcher._();

  static const MethodChannel _canal = MethodChannel('botmp3/devices');

  /// Callback que recibe "conectado" o "desconectado".
  static Future<void> Function(String evento)? onCambio;

  static bool _iniciado = false;

  /// Empieza a escuchar los eventos de audio del sistema.
  static void iniciar() {
    if (_iniciado) return;
    _iniciado = true;
    _canal.setMethodCallHandler((MethodCall call) async {
      final Future<void> Function(String)? callback = onCambio;
      if (callback != null) await callback(call.method);
    });
  }
}
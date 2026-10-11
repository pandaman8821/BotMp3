import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Notificaciones del sistema de BotMp3 (tendencias, avisos de la biblioteca).
///
/// Se apoya en un canal nativo propio (Kotlin) en lugar de añadir un plugin:
/// así no cambia el `pubspec`, no hace falta desugaring y se mantiene el mismo
/// proceso de compilación ya verificado.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const MethodChannel _channel = MethodChannel('botmp3/notifications');
  static const String channelId = 'com.botmp3.app.channel.trends';
  static const String channelName = 'Tendencias musicales';

  /// Muestra una notificación inmediata.
  Future<bool> show({
    required String title,
    required String body,
    int id = 1001,
  }) async {
    try {
      await _channel.invokeMethod<void>('show', <String, dynamic>{
        'id': id,
        'title': title,
        'body': body,
        'channelId': channelId,
        'channelName': channelName,
      });
      return true;
    } on MissingPluginException {
      debugPrint('Notificaciones no disponibles fuera de Android');
      return false;
    } catch (error) {
      debugPrint('No se pudo mostrar la notificación: $error');
      return false;
    }
  }

  /// ¿Están permitidas las notificaciones? (Android 13+ pueden denegarse).
  Future<bool> estanActivas() async {
    try {
      return await _channel.invokeMethod<bool>('notificationsEnabled') ?? true;
    } catch (_) {
      return true;
    }
  }

  /// ¿La app está excluida de la optimización de batería?
  Future<bool> sinRestriccionesDeBateria() async {
    try {
      return await _channel.invokeMethod<bool>('ignoringBatteryOptimizations') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Programa un recordatorio diario a la hora indicada.
  Future<bool> programarDiario({required int hour, required int minute}) async {
    try {
      await _channel.invokeMethod<void>('scheduleDaily', <String, dynamic>{
        'hour': hour,
        'minute': minute,
        'channelId': channelId,
        'channelName': channelName,
      });
      return true;
    } catch (error) {
      debugPrint('No se pudo programar el recordatorio: $error');
      return false;
    }
  }

  /// Cancela el recordatorio programado.
  Future<void> cancelarRecordatorio() async {
    try {
      await _channel.invokeMethod<void>('cancelReminder');
    } catch (error) {
      debugPrint('No se pudo cancelar el recordatorio: $error');
    }
  }
}

import 'package:flutter/services.dart';

/// Versión real del APK instalado.
///
/// Se consulta al sistema (no está escrita en el código), así que la pantalla
/// «Acerca de» se actualiza sola cada vez que instalas una versión nueva.
class AppInfoService {
  const AppInfoService._();

  static const MethodChannel _channel = MethodChannel('botmp3/appinfo');

  static String? _nombre;
  static int? _codigo;
  static bool _consultado = false;

  /// Código de compilación (versionCode) ya consultado, si lo hay.
  static int? get codigoCache => _codigo;

  static Future<void> _consultar() async {
    if (_consultado) return;
    _consultado = true;
    try {
      final Map<dynamic, dynamic>? datos =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('version');
      _nombre = (datos?['name'] as String?)?.trim();
      _codigo = (datos?['code'] as num?)?.toInt();
    } on MissingPluginException {
      // Fuera de Android (o canal no disponible): se deja sin datos.
    } catch (_) {
      // Silencioso: la versión es informativa.
    }
  }

  /// Texto listo para mostrar, por ejemplo «BotMp3 1.4.3 (compilación 14)».
  static Future<String> etiquetaVersion() async {
    await _consultar();
    final String nombre = (_nombre == null || _nombre!.isEmpty) ? 'BotMp3' : _nombre!;
    if (_codigo == null) {
      return nombre.startsWith('BotMp3') ? nombre : 'BotMp3 $nombre';
    }
    return '$nombre (compilación $_codigo)';
  }

  /// Solo el número de versión (1.4.3).
  static Future<String> numeroVersion() async {
    await _consultar();
    return (_nombre == null || _nombre!.isEmpty) ? '—' : _nombre!;
  }
}

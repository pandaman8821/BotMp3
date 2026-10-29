import 'dart:async';

import 'package:home_widget/home_widget.dart';

import '../models/song.dart';

/// Publica en el widget de inicio lo que esta sonando.
class WidgetService {
  const WidgetService._();

  static const String _nombreAndroid = 'BotMp3Widget';

  static String _mmss(Duration d) {
    final int minutos = d.inMinutes;
    final int segundos = d.inSeconds % 60;
    return '$minutos:${segundos.toString().padLeft(2, '0')}';
  }

  static Future<void> actualizar(
    Song cancion, {
    required bool suena,
    Duration posicion = Duration.zero,
    Duration total = Duration.zero,
  }) async {
    try {
      final int progreso = total.inMilliseconds <= 0
          ? 0
          : ((posicion.inMilliseconds / total.inMilliseconds) * 100)
              .clamp(0.0, 100.0)
              .round();
      await HomeWidget.saveWidgetData<bool>('sonando', suena);
      await HomeWidget.saveWidgetData<int>('progreso', progreso);
      await HomeWidget.saveWidgetData<String>('titulo', cancion.title);
      await HomeWidget.saveWidgetData<String>('artista', cancion.artist);
      await HomeWidget.saveWidgetData<String>('album', cancion.album);
      await HomeWidget.saveWidgetData<String>('portada', cancion.coverPath ?? '');
      await HomeWidget.saveWidgetData<String>(
        'tiempo',
        '${_mmss(posicion)} / ${_mmss(total)}',
      );
      await HomeWidget.saveWidgetData<String>(
        'estado',
        suena ? 'Sonando ahora' : 'En pausa',
      );
      await HomeWidget.updateWidget(androidName: _nombreAndroid);
    } catch (_) {
      // El widget es un extra: si falla, nunca debe afectar a la reproduccion.
    }
  }
}
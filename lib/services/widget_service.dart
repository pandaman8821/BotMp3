import 'package:home_widget/home_widget.dart';

import '../models/song.dart';

/// Publica en el widget de inicio lo que está sonando.
///
/// El widget es de solo lectura (título, artista y estado) y al tocarlo abre la
/// app; los controles completos están en el modo coche y en la notificación.
class WidgetService {
  const WidgetService._();

  static const String _nombreAndroid = 'BotMp3Widget';

  static Future<void> actualizar(Song cancion, {required bool suena}) async {
    try {
      await HomeWidget.saveWidgetData<String>('titulo', cancion.title);
      await HomeWidget.saveWidgetData<String>('artista', cancion.artist);
      await HomeWidget.saveWidgetData<String>(
        'estado',
        suena ? 'Sonando ahora' : 'En pausa',
      );
      await HomeWidget.updateWidget(androidName: _nombreAndroid);
    } catch (_) {
      // El widget es un extra: si falla, nunca debe afectar a la reproducción.
    }
  }
}
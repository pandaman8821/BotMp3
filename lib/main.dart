import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';

/// Punto de entrada de BotMp3.
///
/// Se inicializa `just_audio_background` para que la reproducción continúe en
/// segundo plano con notificación y controles en la pantalla de bloqueo.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.botmp3.app.channel.audio',
    androidNotificationChannelName: 'Reproducción BotMp3',
    androidNotificationOngoing: true,
    // Se mantiene en primer plano al pausar: si el servicio baja de
    // prioridad, HyperOS/MIUI lo mata y los controles dejan de responder.
    androidStopForegroundOnPause: false,
    // Icono MONOCROMO obligatorio: con el icono adaptativo Android no crea
    // la notificación y se pierden los controles de la pantalla de bloqueo.
    androidNotificationIcon: 'drawable/ic_stat_botmp3',
  );

  // Sesión de audio como reproductor de música: foco correcto y controles
  // del sistema (bloqueo, auriculares, reloj, Android Auto…).
  final AudioSession session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  final SettingsService settings = await SettingsService.instance();

  // Si el usuario pidió avisos de tendencias, se reprograman al abrir la app
  // (Android borra las alarmas si apaga el móvil; el sistema las conserva si no).
  if (settings.trendsNotify) {
    await NotificationService.instance.programarDiario(
      hour: settings.trendsHour,
      minute: 0,
    );
  }

  runApp(BotMp3App(settings: settings));
}

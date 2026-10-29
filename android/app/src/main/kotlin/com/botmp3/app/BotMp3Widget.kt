package com.botmp3.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.media.AudioManager
import android.view.KeyEvent
import android.widget.ImageView
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** Widget de inicio: cancion actual, progreso y controles de reproduccion. */
class BotMp3Widget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val sonando = widgetData.getBoolean("sonando", false)
        val progreso = widgetData.getInt("progreso", 0).coerceIn(0, 100)
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_botmp3)
            views.setTextViewText(
                R.id.widget_titulo,
                widgetData.getString("titulo", "BotMp3") ?: "BotMp3",
            )
            views.setTextViewText(
                R.id.widget_artista,
                widgetData.getString("artista", "Toca para abrir") ?: "Toca para abrir",
            )
            // Nivel 0..10000 sobre el drawable 'clip': se posiciona sin animacion
            // (el ProgressBar nativo parpadeaba al re-inflar el widget en MIUI).
            views.setInt(R.id.widget_progreso, "setImageLevel", (progreso * 100).coerceIn(0, 10000))
            views.setTextViewText(
                R.id.widget_album,
                widgetData.getString("album", "") ?: "",
            )
            views.setTextViewText(
                R.id.widget_tiempo,
                widgetData.getString("tiempo", "0:00 / 0:00") ?: "0:00 / 0:00",
            )
            val portada = widgetData.getString("portada", "") ?: ""
            if (portada.isNotEmpty()) {
                try {
                    val bmp = BitmapFactory.decodeFile(portada)
                    if (bmp != null) {
                        val escalada = android.graphics.Bitmap.createScaledBitmap(
                            bmp,
                            186,
                            186,
                            true,
                        )
                        views.setImageViewBitmap(R.id.widget_portada, escalada)
                    }
                } catch (_: Throwable) {
                    // Si la caratula falla, se queda el fondo por defecto.
                }
            }
            views.setImageViewResource(
                R.id.widget_play,
                if (sonando) android.R.drawable.ic_media_pause
                else android.R.drawable.ic_media_play,
            )
            views.setOnClickPendingIntent(
                R.id.widget_raiz,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            views.setOnClickPendingIntent(
                R.id.widget_rewind,
                accion(context, id * 10 + 5, WidgetActionReceiver.ACCION_ATRASAR),
            )
            views.setOnClickPendingIntent(
                R.id.widget_prev,
                accion(context, id * 10 + 1, WidgetActionReceiver.ACCION_ANTERIOR),
            )
            views.setOnClickPendingIntent(
                R.id.widget_play,
                accion(context, id * 10 + 2, WidgetActionReceiver.ACCION_PLAY_PAUSA),
            )
            views.setOnClickPendingIntent(
                R.id.widget_next,
                accion(context, id * 10 + 3, WidgetActionReceiver.ACCION_SIGUIENTE),
            )
                        views.setOnClickPendingIntent(
                R.id.widget_forward,
                accion(context, id * 10 + 6, WidgetActionReceiver.ACCION_ADELANTAR),
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun accion(context: Context, codigo: Int, accion: String): PendingIntent {
        val intent = Intent(context, WidgetActionReceiver::class.java).apply {
            this.action = WidgetActionReceiver.ACCION
            putExtra(WidgetActionReceiver.EXTRA, accion)
        }
        return PendingIntent.getBroadcast(
            context,
            codigo,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}

/** Recibe los botones del widget y los reenvia como teclas multimedia. */
class WidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACCION) return
        val tecla = when (intent.getStringExtra(EXTRA)) {
            ACCION_PLAY_PAUSA -> KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
            ACCION_SIGUIENTE -> KeyEvent.KEYCODE_MEDIA_NEXT
            ACCION_ANTERIOR -> KeyEvent.KEYCODE_MEDIA_PREVIOUS
            ACCION_DETENER -> KeyEvent.KEYCODE_MEDIA_STOP
            ACCION_ATRASAR -> KeyEvent.KEYCODE_MEDIA_REWIND
            ACCION_ADELANTAR -> KeyEvent.KEYCODE_MEDIA_FAST_FORWARD
            else -> return
        }
        val audio = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            ?: return
        audio.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, tecla))
        audio.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, tecla))
    }

    companion object {
        const val ACCION = "com.botmp3.app.WIDGET_ACTION"
        const val EXTRA = "accion"
        const val ACCION_PLAY_PAUSA = "play_pausa"
        const val ACCION_SIGUIENTE = "siguiente"
        const val ACCION_ANTERIOR = "anterior"
        const val ACCION_DETENER = "detener"
        const val ACCION_ATRASAR = "atrasar"
        const val ACCION_ADELANTAR = "adelantar"
    }
}
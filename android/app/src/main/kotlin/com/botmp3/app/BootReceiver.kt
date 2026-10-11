package com.botmp3.app

import android.app.AlarmManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import java.util.Calendar

/**
 * Tras reiniciar el móvil se vuelve a programar el aviso diario de tendencias
 * (los sistemas operativos borran las alarmas al apagar).
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != Intent.ACTION_BOOT_COMPLETED) return
        // Preferencias de la app (shared_preferences las guarda con prefijo "flutter.").
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        if (!prefs.getBoolean("flutter.trends_notify", false)) return
        val hora = prefs.getLong("flutter.trends_hour", 20L).toInt()

        val proxima = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, hora)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
        }
        TrendsReminderReceiver.programar(
            context,
            AlarmManager.INTERVAL_DAY,
            proxima.timeInMillis,
        )
    }
}

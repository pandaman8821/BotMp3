package com.botmp3.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import org.json.JSONObject
import java.io.File

/**
 * Recordatorio diario de tendencias.
 *
 * Lee la última lista que la app guardó (`botmp3_trends_v1.json`) y avisa con el
 * «top 3». Si no hay datos, envía un aviso genérico. Después se reprograma para
 * el día siguiente, porque las alarmas inexactas se pierden si el sistema
 * reinicia el proceso.
 */
class TrendsReminderReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        val cuerpo = leerTendencias(context) ?: "Abre BotMp3 y mira qué suena hoy 🔥"
        NotificationHelper.show(
            context,
            ID_NOTIFICACION,
            "🔥 Tendencias musicales de hoy",
            cuerpo,
        )
        programar(
            context,
            AlarmManager.INTERVAL_DAY,
            System.currentTimeMillis() + AlarmManager.INTERVAL_DAY,
        )
    }

    /** Devuelve el resumen del «top 3» guardado por la app, si existe. */
    private fun leerTendencias(context: Context): String? {
        return try {
            val candidatos = listOf(
                File(context.filesDir, ARCHIVO),
                File(File(context.filesDir, "app_flutter"), ARCHIVO),
            )
            val archivo = candidatos.firstOrNull { it.exists() } ?: return null
            val items = JSONObject(archivo.readText()).optJSONArray("items") ?: return null
            val partes = mutableListOf<String>()
            for (i in 0 until minOf(3, items.length())) {
                val item = items.optJSONObject(i) ?: continue
                partes.add("${i + 1}. ${item.optString("title")} — ${item.optString("artist")}")
            }
            if (partes.isEmpty()) null else partes.joinToString(" · ")
        } catch (_: Throwable) {
            null
        }
    }

    companion object {
        const val ARCHIVO = "botmp3_trends_v1.json"
        private const val ID_NOTIFICACION = 2001
        private const val REQUEST_CODE = 2001

        fun programar(context: Context, intervalo: Long, primeraVez: Long) {
            val alarmas = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                ?: return
            alarmas.cancel(pendingIntent(context))
            alarmas.setInexactRepeating(
                AlarmManager.RTC_WAKEUP,
                primeraVez,
                intervalo,
                pendingIntent(context),
            )
        }

        fun cancelar(context: Context) {
            val alarmas = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                ?: return
            alarmas.cancel(pendingIntent(context))
        }

        private fun pendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, TrendsReminderReceiver::class.java)
            return PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}

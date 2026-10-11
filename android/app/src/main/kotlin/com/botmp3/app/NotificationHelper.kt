package com.botmp3.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

/**
 * Notificaciones propias de BotMp3 (tendencias musicales y avisos).
 *
 * Se implementa directamente en Kotlin (sin plugins) para no cambiar el
 * `pubspec` ni el proceso de compilación: menos dependencias, menos riesgo.
 */
object NotificationHelper {
    const val CHANNEL_ID = "com.botmp3.app.channel.trends"
    const val CHANNEL_NAME = "Tendencias musicales"

    fun ensureChannel(
        context: Context,
        id: String = CHANNEL_ID,
        name: String = CHANNEL_NAME,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(id) != null) return
        val canal = NotificationChannel(id, name, NotificationManager.IMPORTANCE_DEFAULT)
        canal.description = "Canciones en tendencia y avisos de BotMp3"
        manager.createNotificationChannel(canal)
    }

    fun show(
        context: Context,
        id: Int,
        title: String,
        body: String,
        channelId: String = CHANNEL_ID,
        channelName: String = CHANNEL_NAME,
    ) {
        ensureChannel(context, channelId, channelName)
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendiente = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notificacion = NotificationCompat.Builder(context, channelId)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setSmallIcon(R.drawable.ic_stat_botmp3)
            .setContentIntent(pendiente)
            .setAutoCancel(true)
            .build()
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        manager.notify(id, notificacion)
    }
}

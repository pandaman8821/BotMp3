package com.botmp3.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** Widget pequeno (2x2): titulo, artista y boton de reproducir/pausar. */
class BotMp3WidgetSmall : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val sonando = widgetData.getBoolean("sonando", false)
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_botmp3_small)
            views.setTextViewText(R.id.small_titulo, widgetData.getString("titulo", "BotMp3") ?: "BotMp3")
            views.setTextViewText(R.id.small_artista, widgetData.getString("artista", "") ?: "")
            views.setImageViewResource(
                R.id.small_play,
                if (sonando) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play,
            )
            views.setOnClickPendingIntent(
                R.id.small_raiz,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            views.setOnClickPendingIntent(
                R.id.small_play,
                accion(context, id * 10 + 2, WidgetActionReceiver.ACCION_PLAY_PAUSA),
            )
            appWidgetManager.partiallyUpdateAppWidget(id, views)
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

/** Widget de barra (4x1): reproducir, titulo/artista y siguiente. */
class BotMp3WidgetBar : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val sonando = widgetData.getBoolean("sonando", false)
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_botmp3_bar)
            views.setTextViewText(R.id.bar_titulo, widgetData.getString("titulo", "BotMp3") ?: "BotMp3")
            views.setTextViewText(R.id.bar_artista, widgetData.getString("artista", "") ?: "")
            views.setImageViewResource(
                R.id.bar_play,
                if (sonando) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play,
            )
            views.setOnClickPendingIntent(
                R.id.bar_raiz,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            views.setOnClickPendingIntent(
                R.id.bar_play,
                accion(context, id * 10 + 2, WidgetActionReceiver.ACCION_PLAY_PAUSA),
            )
            views.setOnClickPendingIntent(
                R.id.bar_next,
                accion(context, id * 10 + 3, WidgetActionReceiver.ACCION_SIGUIENTE),
            )
            appWidgetManager.partiallyUpdateAppWidget(id, views)
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
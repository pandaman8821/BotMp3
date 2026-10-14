package com.botmp3.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** Widget de inicio: muestra lo que suena y abre la app al tocarlo. */
class BotMp3Widget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
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
            views.setTextViewText(
                R.id.widget_estado,
                widgetData.getString("estado", "") ?: "",
            )
            views.setOnClickPendingIntent(
                R.id.widget_raiz,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
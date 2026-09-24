package com.example.kuliahku

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class KuliahKuWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {

            val subject = widgetData.getString(
                "next_subject",
                "Tidak ada jadwal"
            ) ?: "Tidak ada jadwal"

            val time = widgetData.getString(
                "next_time",
                "--:--"
            ) ?: "--:--"

            val room = widgetData.getString(
                "next_room",
                "-"
            ) ?: "-"

            val views = RemoteViews(
                context.packageName,
                R.layout.kuliahku_widget
            )

            views.setTextViewText(
                R.id.widget_title,
                "KuliahKu"
            )

            views.setTextViewText(
                R.id.widget_subject,
                subject
            )

            views.setTextViewText(
                R.id.widget_time,
                time
            )

            views.setTextViewText(
                R.id.widget_room,
                room
            )

            appWidgetManager.updateAppWidget(
                appWidgetId,
                views
            )
        }
    }
}
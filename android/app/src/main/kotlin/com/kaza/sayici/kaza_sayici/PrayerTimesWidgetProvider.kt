package com.kaza.sayici.kaza_sayici

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerTimesWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.prayer_times_widget).apply {
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                val locationName = widgetData.getString("widget_location_name", "Konum") ?: "Konum"
                val currentPrayer = widgetData.getString("widget_current_prayer", "Şu an: Vakit") ?: "Şu an: Vakit"
                val countdownTitle = widgetData.getString("widget_countdown_title", "Kalan Süre") ?: "Kalan Süre"
                val countdownTime = widgetData.getString("widget_countdown_time", "00:00:00") ?: "00:00:00"

                setTextViewText(R.id.widget_location_name, locationName)
                setTextViewText(R.id.widget_current_prayer, currentPrayer)
                setTextViewText(R.id.widget_countdown_title, countdownTitle)
                setTextViewText(R.id.widget_countdown_time, countdownTime)

                val timeImsak = widgetData.getString("time_imsak", "04:50") ?: "04:50"
                val timeGunes = widgetData.getString("time_gunes", "06:20") ?: "06:20"
                val timeOgle = widgetData.getString("time_ogle", "13:05") ?: "13:05"
                val timeIkindi = widgetData.getString("time_ikindi", "17:40") ?: "17:40"
                val timeAksam = widgetData.getString("time_aksam", "19:40") ?: "19:40"
                val timeYatsi = widgetData.getString("time_yatsi", "21:05") ?: "21:05"

                setTextViewText(R.id.time_imsak, timeImsak)
                setTextViewText(R.id.time_gunes, timeGunes)
                setTextViewText(R.id.time_ogle, timeOgle)
                setTextViewText(R.id.time_ikindi, timeIkindi)
                setTextViewText(R.id.time_aksam, timeAksam)
                setTextViewText(R.id.time_yatsi, timeYatsi)

                val activeKey = widgetData.getString("active_vakit_key", "ogle") ?: "ogle"

                setInt(R.id.box_imsak, "setBackgroundResource", if (activeKey == "imsak") R.drawable.widget_badge_active else R.drawable.widget_badge_inactive)
                setInt(R.id.box_gunes, "setBackgroundResource", if (activeKey == "gunes") R.drawable.widget_badge_active else R.drawable.widget_badge_inactive)
                setInt(R.id.box_ogle, "setBackgroundResource", if (activeKey == "ogle") R.drawable.widget_badge_active else R.drawable.widget_badge_inactive)
                setInt(R.id.box_ikindi, "setBackgroundResource", if (activeKey == "ikindi") R.drawable.widget_badge_active else R.drawable.widget_badge_inactive)
                setInt(R.id.box_aksam, "setBackgroundResource", if (activeKey == "aksam") R.drawable.widget_badge_active else R.drawable.widget_badge_inactive)
                setInt(R.id.box_yatsi, "setBackgroundResource", if (activeKey == "yatsi") R.drawable.widget_badge_active else R.drawable.widget_badge_inactive)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

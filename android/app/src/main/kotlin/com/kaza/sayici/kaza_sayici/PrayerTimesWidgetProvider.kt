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
            try {
                val views = RemoteViews(context.packageName, R.layout.prayer_times_widget)
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                val locationName = widgetData.getString("widget_location_name", "Kocaeli, Gölcük") ?: "Kocaeli, Gölcük"
                val currentPrayer = widgetData.getString("widget_current_prayer", "Şu an: Öğle Vakti") ?: "Şu an: Öğle Vakti"
                val countdownTitle = widgetData.getString("widget_countdown_title", "İkindi'ye Kalan") ?: "İkindi'ye Kalan"
                val countdownTime = widgetData.getString("widget_countdown_time", "01:13:00") ?: "01:13:00"

                views.setTextViewText(R.id.widget_location_name, locationName)
                views.setTextViewText(R.id.widget_current_prayer, currentPrayer)
                views.setTextViewText(R.id.widget_countdown_title, countdownTitle)
                views.setTextViewText(R.id.widget_countdown_time, countdownTime)

                val timeImsak = widgetData.getString("time_imsak", "04:52") ?: "04:52"
                val timeGunes = widgetData.getString("time_gunes", "06:21") ?: "06:21"
                val timeOgle = widgetData.getString("time_ogle", "13:05") ?: "13:05"
                val timeIkindi = widgetData.getString("time_ikindi", "17:41") ?: "17:41"
                val timeAksam = widgetData.getString("time_aksam", "19:39") ?: "19:39"
                val timeYatsi = widgetData.getString("time_yatsi", "21:05") ?: "21:05"

                views.setTextViewText(R.id.time_imsak, timeImsak)
                views.setTextViewText(R.id.time_gunes, timeGunes)
                views.setTextViewText(R.id.time_ogle, timeOgle)
                views.setTextViewText(R.id.time_ikindi, timeIkindi)
                views.setTextViewText(R.id.time_aksam, timeAksam)
                views.setTextViewText(R.id.time_yatsi, timeYatsi)

                val activeKey = widgetData.getString("active_vakit_key", "ogle") ?: "ogle"

                views.setInt(R.id.box_imsak, "setBackgroundResource", if (activeKey == "imsak") R.drawable.widget_badge_active else R.drawable.widget_badge_inactive)
                views.setInt(R.id.box_gunes, "setBackgroundResource", if (activeKey == "gunes") R.drawable.widget_badge_active else R.drawable.widget_badge_inactive)
                views.setInt(R.id.box_ogle, "setBackgroundResource", if (activeKey == "ogle") R.drawable.widget_badge_active else R.drawable.widget_badge_inactive)
                views.setInt(R.id.box_ikindi, "setBackgroundResource", if (activeKey == "ikindi") R.drawable.widget_badge_active else R.drawable.widget_badge_inactive)
                views.setInt(R.id.box_aksam, "setBackgroundResource", if (activeKey == "aksam") R.drawable.widget_badge_active else R.drawable.widget_badge_inactive)
                views.setInt(R.id.box_yatsi, "setBackgroundResource", if (activeKey == "yatsi") R.drawable.widget_badge_active else R.drawable.widget_badge_inactive)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}

package com.kaza.sayici.kaza_sayici

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider

class CurrentPrayerTickWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.current_prayer_tick_widget).apply {
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.layout_info, pendingIntent)

                val activePrayerName = widgetData.getString("active_prayer_name", "Öğle Namazı") ?: "Öğle Namazı"
                val activePrayerTime = widgetData.getString("active_prayer_time", "13:05 • Kaza Takipçisi") ?: "13:05 • Kaza Takipçisi"
                val isTicked = widgetData.getBoolean("active_prayer_ticked", false)
                val activeKey = widgetData.getString("active_prayer_key", "ogle") ?: "ogle"

                setTextViewText(R.id.widget_active_prayer_name, activePrayerName)
                setTextViewText(R.id.widget_active_prayer_time, activePrayerTime)

                if (isTicked) {
                    setTextViewText(R.id.widget_active_prayer_status, "Kılındı ✓")
                    setTextColor(R.id.widget_active_prayer_status, 0xFF10B981.toInt())
                    setInt(R.id.btn_toggle_tick, "setBackgroundResource", R.drawable.widget_tick_on)
                    setTextViewText(R.id.widget_tick_text, "✓")
                } else {
                    setTextViewText(R.id.widget_active_prayer_status, "Kılınmadı (Tikleyin)")
                    setTextColor(R.id.widget_active_prayer_status, 0xFFF59E0B.toInt())
                    setInt(R.id.btn_toggle_tick, "setBackgroundResource", R.drawable.widget_tick_off)
                    setTextViewText(R.id.widget_tick_text, "✓")
                }

                val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("kazatakip://toggleTick?key=$activeKey")
                )
                setOnClickPendingIntent(R.id.btn_toggle_tick, backgroundIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

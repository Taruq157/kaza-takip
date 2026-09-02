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
            try {
                val views = RemoteViews(context.packageName, R.layout.current_prayer_tick_widget)
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.layout_info, pendingIntent)
                views.setOnClickPendingIntent(R.id.layout_icon, pendingIntent)

                val activePrayerName = widgetData.getString("active_prayer_name", "Öğle") ?: "Öğle"
                val activePrayerSubtitle = widgetData.getString("active_prayer_subtitle", "4 Rekât Farz • Kaza Takipçisi") ?: "4 Rekât Farz • Kaza Takipçisi"
                val activeEmoji = widgetData.getString("active_prayer_emoji", "☀️") ?: "☀️"
                val isTicked = widgetData.getBoolean("active_prayer_ticked", false)
                val activeKey = widgetData.getString("active_prayer_key", "ogle") ?: "ogle"

                views.setTextViewText(R.id.widget_active_prayer_name, activePrayerName)
                views.setTextViewText(R.id.widget_prayer_emoji, activeEmoji)

                if (isTicked) {
                    views.setTextViewText(R.id.widget_active_prayer_status, "Bugün Kılındı ✓")
                    views.setTextColor(R.id.widget_active_prayer_status, 0xFF10B981.toInt())
                    views.setInt(R.id.btn_toggle_tick, "setBackgroundResource", R.drawable.widget_tick_on)
                    views.setTextViewText(R.id.widget_tick_text, "✓")
                } else {
                    views.setTextViewText(R.id.widget_active_prayer_status, activePrayerSubtitle)
                    views.setTextColor(R.id.widget_active_prayer_status, 0xFF94A3B8.toInt())
                    views.setInt(R.id.btn_toggle_tick, "setBackgroundResource", R.drawable.widget_tick_off)
                    views.setTextViewText(R.id.widget_tick_text, "")
                }

                val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("kazatakip://toggleTick?key=$activeKey")
                )
                views.setOnClickPendingIntent(R.id.btn_toggle_tick, backgroundIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}

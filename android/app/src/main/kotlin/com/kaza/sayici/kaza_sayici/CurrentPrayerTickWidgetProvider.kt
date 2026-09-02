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

                val isDark = widgetData.getBoolean("widget_is_dark", true)
                val activePrayerName = widgetData.getString("active_prayer_name", "Öğle") ?: "Öğle"
                val activePrayerSubtitle = widgetData.getString("active_prayer_subtitle", "4 Rekât Farz • Kaza Takipçisi") ?: "4 Rekât Farz • Kaza Takipçisi"
                val activeEmoji = widgetData.getString("active_prayer_emoji", "☀️") ?: "☀️"
                val isTicked = widgetData.getBoolean("active_prayer_ticked", false)
                val activeKey = widgetData.getString("active_prayer_key", "ogle") ?: "ogle"

                views.setTextViewText(R.id.widget_active_prayer_name, activePrayerName)
                views.setTextViewText(R.id.widget_prayer_emoji, activeEmoji)

                // Theme styling
                if (isDark) {
                    views.setInt(R.id.widget_tick_container, "setBackgroundResource", R.drawable.widget_bg_dark)
                    views.setInt(R.id.layout_icon, "setBackgroundResource", R.drawable.widget_pill_bg_dark)
                    views.setTextColor(R.id.widget_active_prayer_name, 0xFFFFFFFF.toInt())
                } else {
                    views.setInt(R.id.widget_tick_container, "setBackgroundResource", R.drawable.widget_bg_light)
                    views.setInt(R.id.layout_icon, "setBackgroundResource", R.drawable.widget_pill_bg_light)
                    views.setTextColor(R.id.widget_active_prayer_name, 0xFF0F172A.toInt())
                }

                if (isTicked) {
                    views.setTextViewText(R.id.widget_active_prayer_status, "Bugün Kılındı ✓")
                    views.setTextColor(R.id.widget_active_prayer_status, if (isDark) 0xFF10B981.toInt() else 0xFF059669.toInt())
                    views.setImageViewResource(R.id.btn_toggle_tick, R.drawable.ic_tick_checked)
                } else {
                    views.setTextViewText(R.id.widget_active_prayer_status, activePrayerSubtitle)
                    views.setTextColor(R.id.widget_active_prayer_status, if (isDark) 0xFF94A3B8.toInt() else 0xFF64748B.toInt())
                    views.setImageViewResource(R.id.btn_toggle_tick, if (isDark) R.drawable.ic_tick_unchecked_dark else R.drawable.ic_tick_unchecked_light)
                }

                val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("kazatakip://toggleTick?key=$activeKey")
                )
                views.setOnClickPendingIntent(R.id.btn_toggle_tick, backgroundIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                e.printStackTrace()
            }
        }
    }
}

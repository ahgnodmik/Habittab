package com.habittab.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

class HabitWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val titles = parseStrings(widgetData.getString("habit_titles", null))
        val checks = parseBooleans(widgetData.getString("habit_checks", null))
        val buttonIds = intArrayOf(
            R.id.habit_btn_0,
            R.id.habit_btn_1,
            R.id.habit_btn_2,
            R.id.habit_btn_3,
        )

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.home_widget_layout)
            buttonIds.forEachIndexed { index, buttonId ->
                if (index < titles.size) {
                    val checked = checks.getOrElse(index) { false }
                    val prefix = if (checked) "\u2713 " else ""
                    views.setViewVisibility(buttonId, View.VISIBLE)
                    views.setTextViewText(buttonId, prefix + titles[index])
                    views.setOnClickPendingIntent(
                        buttonId,
                        HomeWidgetBackgroundIntent.getBroadcast(
                            context,
                            Uri.parse("habittab://toggle?index=$index"),
                        ),
                    )
                } else {
                    views.setViewVisibility(buttonId, View.GONE)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun parseStrings(value: String?): List<String> {
        if (value == null) return emptyList()
        return runCatching {
            val json = JSONArray(value)
            List(json.length()) { index -> json.getString(index) }
        }.getOrDefault(emptyList())
    }

    private fun parseBooleans(value: String?): List<Boolean> {
        if (value == null) return emptyList()
        return runCatching {
            val json = JSONArray(value)
            List(json.length()) { index -> json.getBoolean(index) }
        }.getOrDefault(emptyList())
    }
}

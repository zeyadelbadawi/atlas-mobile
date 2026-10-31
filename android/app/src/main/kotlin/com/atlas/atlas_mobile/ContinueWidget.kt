package com.atlas.atlas_mobile

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * "Continue learning" on the home screen. The app writes what to show
 * (lib/app/home_widgets.dart), already in its language; this lays it out.
 * A tap opens the app on the course (or the task) it names.
 */
class ContinueWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, views(context, widgetData))
        }
    }

    private fun views(context: Context, data: SharedPreferences): RemoteViews {
        val v = RemoteViews(context.packageName, R.layout.widget_continue)
        // The app's language, not the phone's, decides the direction.
        v.setInt(
            R.id.widget_root,
            "setLayoutDirection",
            if (data.getBoolean("rtl", false)) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR,
        )

        val label = data.getString("label", null)
        if (label != null) v.setTextViewText(R.id.widget_label, label)
        v.setTextViewText(R.id.widget_academy, data.getString("academy", "Atlas"))

        val course = data.getString("course", "") ?: ""
        val hasCourse = data.getBoolean("signedIn", false) && course.isNotEmpty()
        val shown = if (hasCourse) View.VISIBLE else View.GONE
        v.setViewVisibility(R.id.widget_course, shown)
        v.setViewVisibility(R.id.widget_progress_row, shown)
        v.setViewVisibility(R.id.widget_empty, if (hasCourse) View.GONE else View.VISIBLE)

        if (hasCourse) {
            v.setTextViewText(R.id.widget_course, course)
            // Small numbers arrive as Int; tolerate a Long rather than crash.
            val pct = try {
                data.getInt("percent", 0)
            } catch (e: ClassCastException) {
                data.getLong("percent", 0L).toInt()
            }
            v.setProgressBar(R.id.widget_progress, 100, pct, false)
            v.setTextViewText(R.id.widget_percent, data.getString("percentText", ""))
        } else {
            v.setTextViewText(R.id.widget_empty, data.getString("empty", ""))
        }
        line(v, R.id.widget_lesson, if (hasCourse) data.getString("lesson", "") else "")
        line(v, R.id.widget_due, data.getString("due", ""))

        val path = data.getString("path", "/home") ?: "/home"
        val uri = Uri.parse("atlaswidget://open").buildUpon()
            .appendQueryParameter("path", path).build()
        v.setOnClickPendingIntent(
            R.id.widget_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, uri),
        )
        return v
    }

    /** A text line, hidden when there is nothing to say. */
    private fun line(v: RemoteViews, id: Int, text: String?) {
        if (text.isNullOrEmpty()) {
            v.setViewVisibility(id, View.GONE)
        } else {
            v.setViewVisibility(id, View.VISIBLE)
            v.setTextViewText(id, text)
        }
    }
}

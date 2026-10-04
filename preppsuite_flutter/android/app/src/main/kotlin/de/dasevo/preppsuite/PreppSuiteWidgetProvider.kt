package de.dasevo.preppsuite

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * The overview's two lamps on the home screen (#105).
 *
 * Draws what the app last published through home_widget -- texts that are
 * already translated, and two states that only pick a colour. Nothing is
 * worked out here: the lamps are computed by the same Dart code as the
 * overview, so the home screen cannot disagree with the app.
 *
 * Before the app has run once there is nothing published, and the widget
 * says so instead of showing a lamp it has no data for.
 */
class PreppSuiteWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    for (id in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.preppsuite_widget)
      val supplyText = widgetData.getString("supplyText", null)

      if (supplyText == null) {
        views.setTextViewText(R.id.widget_supply_text, context.getString(R.string.widget_open_app))
        views.setTextViewText(R.id.widget_situation_text, "")
        views.setTextViewText(R.id.widget_updated, "")
        views.setTextColor(R.id.widget_supply_dot, GREY)
        views.setTextColor(R.id.widget_situation_dot, Color.TRANSPARENT)
      } else {
        views.setTextViewText(R.id.widget_supply_text, supplyText)
        views.setTextViewText(
            R.id.widget_situation_text, widgetData.getString("situationText", ""))
        views.setTextViewText(R.id.widget_updated, widgetData.getString("updatedText", ""))
        views.setTextColor(
            R.id.widget_supply_dot, supplyColour(widgetData.getString("supplyState", null)))
        views.setTextColor(
            R.id.widget_situation_dot,
            situationColour(widgetData.getString("situationState", null)))
      }

      // A tap opens the app, on whatever screen it last showed.
      views.setOnClickPendingIntent(
          R.id.widget_root, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
      appWidgetManager.updateAppWidget(id, views)
    }
  }

  private companion object {
    const val GREY = 0xFF9E9E9E.toInt()

    /** The overview's own lamp colours: the app's primary green and its amber. */
    fun supplyColour(state: String?): Int =
        when (state) {
          "covered" -> 0xFF2E7D32.toInt()
          "short" -> 0xFFE0A900.toInt()
          else -> GREY
        }

    /**
     * A saturated scale of its own, ordered like the app's. The app's
     * severity colours are pale banner backgrounds (see
     * warning_severity_l10n.dart), and a pale dot on a home screen
     * wallpaper is a dot nobody sees. The text beside it names the level.
     */
    fun situationColour(state: String?): Int =
        when (state) {
          "extreme" -> 0xFFB71C1C.toInt()
          "severe" -> 0xFFE65100.toInt()
          "moderate" -> 0xFFF9A825.toInt()
          "minor" -> 0xFFFDD835.toInt()
          else -> GREY
        }
  }
}

package com.example.BKN

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Widget provider per mostrare una location sulla home screen Android.
 * Integrato con HomeWidgetService tramite home_widget plugin.
 */
class BKNLocationWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Widget aggiunto per la prima volta
    }

    override fun onDisabled(context: Context) {
        // Ultimo widget rimosso
    }

    companion object {
        private const val WIDGET_NAME = "BKNLocationWidget"
        private const val KEY_LOCATION_LABEL = "location_label"
        private const val KEY_LOCATION_LAT = "location_lat"
        private const val KEY_LOCATION_LNG = "location_lng"
        private const val KEY_LOCATION_ID = "location_id"

        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // Leggi i dati salvati da Flutter tramite HomeWidgetPlugin
            val widgetData = HomeWidgetPlugin.getData(context)
            
            val locationLabel = widgetData.getString(KEY_LOCATION_LABEL, null)
            val locationLat = widgetData.getString(KEY_LOCATION_LAT, null)
            val locationLng = widgetData.getString(KEY_LOCATION_LNG, null)
            val locationId = widgetData.getString(KEY_LOCATION_ID, null)

            // Crea il layout del widget
            val views = RemoteViews(context.packageName, R.layout.bkn_widget_layout)

            if (locationLabel != null && locationLat != null && locationLng != null) {
                // Mostra i dati della location
                views.setTextViewText(R.id.widget_location_label, locationLabel)
                views.setTextViewText(
                    R.id.widget_location_coordinates,
                    "Lat: $locationLat, Lng: $locationLng"
                )
            } else {
                // Nessuna location configurata
                views.setTextViewText(R.id.widget_location_label, "Nessuna location")
                views.setTextViewText(R.id.widget_location_coordinates, "Tocca per configurare")
            }

            // Setup click listener per aprire l'app
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                if (locationId != null) {
                    // Passa l'ID della location per deep link
                    putExtra("location_id", locationId)
                }
            }

            val pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            views.setOnClickPendingIntent(R.id.widget_title, pendingIntent)

            // Aggiorna il widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

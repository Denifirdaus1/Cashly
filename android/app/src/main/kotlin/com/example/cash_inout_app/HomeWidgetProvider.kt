package com.example.cash_inout_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class HomeWidgetProvider : AppWidgetProvider() {
    companion object {
        const val INCOME_KEY = "today_income"
        const val EXPENSE_KEY = "today_expense"
        const val BALANCE_KEY = "current_balance"
        const val ACTION_CLICK = "com.example.cash_inout_app.ACTION_CLICK"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_layout)
        
        // Get data from HomeWidget plugin
        val sharedPref = HomeWidgetPlugin.getData(context)
        val income = sharedPref.getInt(INCOME_KEY, 0)
        val expense = sharedPref.getInt(EXPENSE_KEY, 0)
        val balance = sharedPref.getInt(BALANCE_KEY, 0)
        
        // Format currency in IDR
        val formattedIncome = formatCurrency(income)
        val formattedExpense = formatCurrency(expense)
        val formattedBalance = formatCurrency(balance)
        
        // Update views - only balance is shown in new widget design
        views.setTextViewText(R.id.tv_widget_balance, formattedBalance)
        
        // Set up click intent for entire widget (no button in new design)
        // setupButtonClickListener(context, views, R.id.open_app_button, ACTION_CLICK)
        
        // Set up click intent for entire widget
        setupWidgetClickListener(context, views)
        
        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun setupButtonClickListener(context: Context, views: RemoteViews, buttonId: Int, action: String) {
        val intent = Intent(context, HomeWidgetProvider::class.java).apply {
            this.action = action
            data = Uri.parse("custom://action_$buttonId")
        }
        
        val pendingIntent = android.app.PendingIntent.getBroadcast(
            context,
            buttonId,
            intent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
        
        views.setOnClickPendingIntent(buttonId, pendingIntent)
    }

    private fun setupWidgetClickListener(context: Context, views: RemoteViews) {
        val intent = Intent(context, HomeWidgetProvider::class.java).apply {
            action = ACTION_CLICK
            data = Uri.parse("custom://widget_click")
        }
        
        val pendingIntent = android.app.PendingIntent.getBroadcast(
            context,
            0,
            intent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
        
        // Set click listener for the entire widget (root layout)
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            ACTION_CLICK -> {
                // Launch the Flutter app
                val flutterIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                flutterIntent?.let {
                    it.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    context.startActivity(it)
                }
            }
        }
    }

    private fun formatCurrency(amount: Int): String {
        return "Rp${amount.toString().reversed().chunked(3).joinToString(".").reversed()}"
    }
}
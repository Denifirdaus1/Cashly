import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../data/storage/local_storage.dart';
import '../data/models/transaction.dart';

class WidgetService {
  static const String _incomeKey = 'today_income';
  static const String _expenseKey = 'today_expense';
  static const String _balanceKey = 'current_balance';
  static const String _dateKey = 'widget_date';

  static Future<void> initializeWidget() async {
    await updateWidgetData();
  }

  static Future<void> updateWidgetData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = _formatDate(today);

    // Get real data from LocalStorage
    final transactions = await LocalStorageService.getAllTransactions();

    // Calculate today's income and expense
    final todayTransactions = transactions.where(
      (tx) =>
          tx.date.year == today.year &&
          tx.date.month == today.month &&
          tx.date.day == today.day,
    );

    final todayIncome = todayTransactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);

    final todayExpense = todayTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);

    // Calculate total balance
    final balance = transactions.fold(
      0.0,
      (sum, item) =>
          sum +
          (item.type == TransactionType.income ? item.amount : -item.amount),
    );

    // Convert to int for widget display
    final incomeInt = todayIncome.toInt();
    final expenseInt = todayExpense.toInt();
    final balanceInt = balance.toInt();

    // Update SharedPreferences for widget
    await prefs.setInt(_incomeKey, incomeInt);
    await prefs.setInt(_expenseKey, expenseInt);
    await prefs.setInt(_balanceKey, balanceInt);
    await prefs.setString(_dateKey, todayString);

    // Update widget data
    if (!kIsWeb) {
      await HomeWidget.saveWidgetData<int>(_incomeKey, incomeInt);
      await HomeWidget.saveWidgetData<int>(_expenseKey, expenseInt);
      await HomeWidget.saveWidgetData<int>(_balanceKey, balanceInt);

      // Trigger widget update
      await HomeWidget.updateWidget(
        name: 'CashInOutWidget',
        androidName: 'HomeWidgetProvider',
      );
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static Future<Map<String, dynamic>> getTodaySummary() async {
    final transactions = await LocalStorageService.getAllTransactions();
    final today = DateTime.now();

    // Calculate today's income and expense
    final todayTransactions = transactions.where(
      (tx) =>
          tx.date.year == today.year &&
          tx.date.month == today.month &&
          tx.date.day == today.day,
    );

    final todayIncome = todayTransactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);

    final todayExpense = todayTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);

    // Calculate total balance
    final balance = transactions.fold(
      0.0,
      (sum, item) =>
          sum +
          (item.type == TransactionType.income ? item.amount : -item.amount),
    );

    return {
      'income': todayIncome.toInt(),
      'expense': todayExpense.toInt(),
      'balance': balance.toInt(),
    };
  }
}

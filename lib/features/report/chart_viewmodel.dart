import 'package:cash_inout_app/data/storage/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:cash_inout_app/data/models/transaction.dart'; // Updated import
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ChartViewModel extends ChangeNotifier {
  final LocalStorageService _localStorageService;
  List<Transaction> transactions = []; // Updated to Transaction
  List<Transaction> filteredTransactions = []; // Filtered transactions based on date range
  DateTime? startDate;
  DateTime? endDate;

  ChartViewModel(this._localStorageService);

  Future<void> loadTransactions() async {
    transactions = await LocalStorageService.getAllTransactions();
    filteredTransactions = transactions;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    startDate = start;
    endDate = end;
    _applyDateFilter();
    notifyListeners();
  }

  void clearDateFilter() {
    startDate = null;
    endDate = null;
    filteredTransactions = transactions;
    notifyListeners();
  }

  void _applyDateFilter() {
    if (startDate == null && endDate == null) {
      filteredTransactions = transactions;
      return;
    }

    filteredTransactions = transactions.where((transaction) {
      if (startDate != null && transaction.date.isBefore(startDate!)) {
        return false;
      }
      if (endDate != null && transaction.date.isAfter(endDate!)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<FlSpot> getDailyIncomeSpots() {
    Map<String, double> dailyIncome = {};

    for (var transaction in filteredTransactions) {
      String dateKey = DateFormat('dd/MM').format(transaction.date);
      if (transaction.type == TransactionType.income) {
        dailyIncome.update(
          dateKey,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }

    List<String> sortedDates = dailyIncome.keys.toList();
    sortedDates.sort((a, b) {
      DateTime dateA = DateFormat('dd/MM').parse(a);
      DateTime dateB = DateFormat('dd/MM').parse(b);
      return dateA.compareTo(dateB);
    });

    List<FlSpot> spots = [];
    for (int i = 0; i < sortedDates.length; i++) {
      String date = sortedDates[i];
      double income = dailyIncome[date] ?? 0.0;
      spots.add(FlSpot(i.toDouble(), income));
    }
    return spots;
  }

  List<FlSpot> getDailyExpenseSpots() {
    Map<String, double> dailyExpense = {};

    for (var transaction in filteredTransactions) {
      String dateKey = DateFormat('dd/MM').format(transaction.date);
      if (transaction.type == TransactionType.expense) {
        dailyExpense.update(
          dateKey,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }

    List<String> sortedDates = dailyExpense.keys.toList();
    sortedDates.sort((a, b) {
      DateTime dateA = DateFormat('dd/MM').parse(a);
      DateTime dateB = DateFormat('dd/MM').parse(b);
      return dateA.compareTo(dateB);
    });

    List<FlSpot> spots = [];
    for (int i = 0; i < sortedDates.length; i++) {
      String date = sortedDates[i];
      double expense = dailyExpense[date] ?? 0.0;
      spots.add(FlSpot(i.toDouble(), expense));
    }
    return spots;
  }

  String getDailyLabel(int value) {
    List<String> sortedDates =
        (filteredTransactions.map((e) => DateFormat('dd/MM').format(e.date)).toList())
            .toSet()
            .toList();
    sortedDates.sort((a, b) {
      DateTime dateA = DateFormat('dd/MM').parse(a);
      DateTime dateB = DateFormat('dd/MM').parse(b);
      return dateA.compareTo(dateB);
    });
    if (value >= 0 && value < sortedDates.length) {
      return sortedDates[value];
    }
    return '';
  }

  List<FlSpot> getMonthlyIncomeSpots() {
    Map<String, double> monthlyIncome = {};

    for (var transaction in filteredTransactions) {
      String dateKey = DateFormat('yyyy-MM').format(transaction.date);
      if (transaction.type == TransactionType.income) {
        monthlyIncome.update(
          dateKey,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }

    List<String> sortedMonths = monthlyIncome.keys.toList();
    sortedMonths.sort((a, b) {
      DateTime dateA = DateFormat('yyyy-MM').parse(a);
      DateTime dateB = DateFormat('yyyy-MM').parse(b);
      return dateA.compareTo(dateB);
    });

    List<FlSpot> spots = [];
    for (int i = 0; i < sortedMonths.length; i++) {
      String month = sortedMonths[i];
      double income = monthlyIncome[month] ?? 0.0;
      spots.add(FlSpot(i.toDouble(), income));
    }
    return spots;
  }

  List<FlSpot> getMonthlyExpenseSpots() {
    Map<String, double> monthlyExpense = {};

    for (var transaction in filteredTransactions) {
      String dateKey = DateFormat('yyyy-MM').format(transaction.date);
      if (transaction.type == TransactionType.expense) {
        monthlyExpense.update(
          dateKey,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }

    List<String> sortedMonths = monthlyExpense.keys.toList();
    sortedMonths.sort((a, b) {
      DateTime dateA = DateFormat('yyyy-MM').parse(a);
      DateTime dateB = DateFormat('yyyy-MM').parse(b);
      return dateA.compareTo(dateB);
    });

    List<FlSpot> spots = [];
    for (int i = 0; i < sortedMonths.length; i++) {
      String month = sortedMonths[i];
      double expense = monthlyExpense[month] ?? 0.0;
      spots.add(FlSpot(i.toDouble(), expense));
    }
    return spots;
  }

  String getMonthlyLabel(int value) {
    List<String> sortedMonths =
        (filteredTransactions.map((e) => DateFormat('yyyy-MM').format(e.date)).toList())
            .toSet()
            .toList();
    sortedMonths.sort((a, b) {
      DateTime dateA = DateFormat('yyyy-MM').parse(a);
      DateTime dateB = DateFormat('yyyy-MM').parse(b);
      return dateA.compareTo(dateB);
    });
    if (value >= 0 && value < sortedMonths.length) {
      return sortedMonths[value];
    }
    return '';
  }

  List<PieChartSectionData> getDailyIncomeExpensePieSections() {
    double totalIncome = 0;
    double totalExpense = 0;

    for (var transaction in filteredTransactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    }

    double total = totalIncome + totalExpense;
    if (total == 0) return [];

    List<PieChartSectionData> sections = [];
    
    if (totalIncome > 0) {
      double incomePercentage = (totalIncome / total) * 100;
      sections.add(
        PieChartSectionData(
          color: Colors.green.shade600,
          value: totalIncome,
          title: '${incomePercentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black26),
            ],
          ),
        ),
      );
    }
    
    if (totalExpense > 0) {
      double expensePercentage = (totalExpense / total) * 100;
      sections.add(
        PieChartSectionData(
          color: Colors.red.shade600,
          value: totalExpense,
          title: '${expensePercentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black26),
            ],
          ),
        ),
      );
    }
    
    return sections;
  }



  double getMaxValue() {
    double maxIncome = 0;
    double maxExpense = 0;
    
    Map<String, double> dailyIncome = {};
    Map<String, double> dailyExpense = {};

    for (var transaction in filteredTransactions) {
      String dateKey = DateFormat('dd/MM').format(transaction.date);
      if (transaction.type == TransactionType.income) {
        dailyIncome.update(
          dateKey,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      } else {
        dailyExpense.update(
          dateKey,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }
    
    if (dailyIncome.isNotEmpty) {
      maxIncome = dailyIncome.values.reduce((a, b) => a > b ? a : b);
    }
    if (dailyExpense.isNotEmpty) {
      maxExpense = dailyExpense.values.reduce((a, b) => a > b ? a : b);
    }
    
    return maxIncome > maxExpense ? maxIncome : maxExpense;
  }
}

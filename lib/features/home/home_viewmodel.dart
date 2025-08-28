import 'package:flutter/material.dart';
import 'package:cash_inout_app/data/models/transaction.dart';
import 'package:cash_inout_app/data/storage/local_storage.dart';
import 'package:intl/intl.dart';

class HomeViewModel extends ChangeNotifier {
  List<Transaction> _allTransactions = [];
  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;

  final Map<String, List<Transaction>> _groupedTransactions = {};
  Map<String, List<Transaction>> get groupedTransactions => _groupedTransactions;

  DateTime? _selectedDate;
  DateTime? get selectedDate => _selectedDate;

  double _todaySummary = 0.0;
  double get todaySummary => _todaySummary;

  double _balance = 0.0;
  double get balance => _balance;

  double _todayIncome = 0.0;
  double get todayIncome => _todayIncome;

  double _todayExpense = 0.0;
  double get todayExpense => _todayExpense;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _hasError = false;
  bool get hasError => _hasError;

  HomeViewModel() {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    try {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      notifyListeners();

      // Check if storage is initialized
      if (!LocalStorageService.isInitialized) {
        throw Exception('Storage belum diinisialisasi. Silakan restart aplikasi.');
      }

      _allTransactions = await LocalStorageService.getAllTransactions();
      _applyDateFilter();
      _calculateTodaySummary();
      _calculateBalance();
      
      debugPrint('Transactions loaded successfully: ${_allTransactions.length} items');
    } catch (e, stackTrace) {
      _hasError = true;
      _errorMessage = e.toString();
      _allTransactions = [];
      _transactions = [];
      _groupedTransactions.clear();
      _balance = 0.0;
      _todayIncome = 0.0;
      _todayExpense = 0.0;
      _todaySummary = 0.0;
      
      debugPrint('Error loading transactions: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> retryLoadTransactions() async {
    await loadTransactions();
  }

  void filterByDate(DateTime? date) {
    _selectedDate = date;
    _applyDateFilter();
    notifyListeners();
  }

  void clearDateFilter() {
    _selectedDate = null;
    _applyDateFilter();
    notifyListeners();
  }

  void _applyDateFilter() {
    if (_selectedDate == null) {
      _transactions = List.from(_allTransactions);
    } else {
      _transactions = _allTransactions.where((tx) =>
          tx.date.year == _selectedDate!.year &&
          tx.date.month == _selectedDate!.month &&
          tx.date.day == _selectedDate!.day).toList();
    }
    _groupTransactionsByDate();
  }

  void _groupTransactionsByDate() {
    _groupedTransactions.clear();
    
    // Sort transactions by date (newest first)
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    for (final transaction in _transactions) {
      final transactionDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      
      String dateKey;
      if (transactionDate == today) {
        dateKey = 'Hari Ini';
      } else if (transactionDate == yesterday) {
        dateKey = 'Kemarin';
      } else {
        dateKey = DateFormat('dd MMMM yyyy', 'id_ID').format(transaction.date);
      }
      
      if (!_groupedTransactions.containsKey(dateKey)) {
        _groupedTransactions[dateKey] = [];
      }
      _groupedTransactions[dateKey]!.add(transaction);
    }
  }

  void _calculateBalance() {
    _balance = _allTransactions.fold(
      0.0,
      (sum, item) =>
          sum +
          (item.type == TransactionType.income ? item.amount : -item.amount),
    );
  }

  void _calculateTodaySummary() {
    final today = DateTime.now();
    final todayTransactions = _transactions.where(
      (tx) =>
          tx.date.year == today.year &&
          tx.date.month == today.month &&
          tx.date.day == today.day,
    );

    _todayIncome = todayTransactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);

    _todayExpense = todayTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);

    _todaySummary = _todayIncome - _todayExpense;
  }
}

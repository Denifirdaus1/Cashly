import 'package:flutter/material.dart';
import 'package:cash_inout_app/data/models/transaction.dart'; // Updated import
import 'package:cash_inout_app/data/storage/local_storage.dart';
import 'package:cash_inout_app/services/widget_service.dart';

class AddTransactionViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  Future<bool> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
  }) async {
    try {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      notifyListeners();

      // Validate input
      if (title.trim().isEmpty) {
        throw Exception('Judul transaksi tidak boleh kosong');
      }
      if (amount <= 0) {
        throw Exception('Jumlah transaksi harus lebih dari 0');
      }

      // Check if storage is initialized
      if (!LocalStorageService.isInitialized) {
        throw Exception('Storage belum diinisialisasi. Silakan restart aplikasi.');
      }

      final newTransaction = Transaction(
        id: DateTime.now().toString(), // Simple unique ID
        title: title.trim(),
        amount: amount,
        date: DateTime.now(),
        type: type,
        category: type == TransactionType.expense ? 'Uncategorized' : 'Income',
      );
      
      await LocalStorageService.addTransaction(newTransaction);

      // Update widget data with real-time information
      try {
        await WidgetService.updateWidgetData();
      } catch (e) {
        debugPrint('Warning: Failed to update widget data: $e');
        // Don't throw error for widget update failure
      }

      debugPrint('Transaction added successfully: ${newTransaction.title}');
      return true;
    } catch (e, stackTrace) {
      _hasError = true;
      _errorMessage = e.toString();
      debugPrint('Error adding transaction: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
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
}

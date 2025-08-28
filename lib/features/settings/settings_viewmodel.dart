import 'package:flutter/material.dart';
import 'package:cash_inout_app/data/storage/local_storage.dart';
import 'package:cash_inout_app/data/models/transaction.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class SettingsViewModel extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> exportData(BuildContext context) async {
    try {
      _setLoading(true);

      // Get all transactions from local storage
      final transactions = await LocalStorageService.getAllTransactions();

      if (transactions.isEmpty) {
        _showSnackBar(context, 'Tidak ada data untuk di-export', Colors.orange);
        return;
      }

      // Convert transactions to JSON
      final exportData = {
        'app_name': 'Cashly',
        'export_date': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'transactions': transactions
            .map(
              (transaction) => {
                'id': transaction.id,
                'title': transaction.title,
                'amount': transaction.amount,
                'type': transaction.type.toString(),
                'date': transaction.date.toIso8601String(),
                'category': transaction.category,
              },
            )
            .toList(),
      };

      // Convert to JSON string
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final fileName =
          'cashly_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');

      // Write to file
      await file.writeAsString(jsonString);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Backup data Cashly - ${transactions.length} transaksi',
        subject: 'Cashly Data Backup',
      );

      _showSnackBar(
        context,
        'Data berhasil di-export! ${transactions.length} transaksi',
        Colors.green,
      );
    } catch (e) {
      _showSnackBar(context, 'Gagal export data: $e', Colors.red);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> importData(BuildContext context) async {
    try {
      _setLoading(true);

      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        _showSnackBar(context, 'Tidak ada file yang dipilih', Colors.orange);
        return;
      }

      final file = File(result.files.first.path!);

      // Read file content
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate file format
      if (!jsonData.containsKey('app_name') ||
          jsonData['app_name'] != 'Cashly' ||
          !jsonData.containsKey('transactions')) {
        _showSnackBar(context, 'Format file tidak valid', Colors.red);
        return;
      }

      // Show confirmation dialog
      final confirmed = await _showConfirmationDialog(context);
      if (!confirmed) return;

      // Parse transactions
      final transactionsData = jsonData['transactions'] as List<dynamic>;
      final transactions = <Transaction>[];

      for (final transactionData in transactionsData) {
        try {
          final transaction = Transaction(
            id: transactionData['id'] as String,
            title: transactionData['title'] as String,
            amount: (transactionData['amount'] as num).toDouble(),
            type: transactionData['type'] == 'TransactionType.income'
                ? TransactionType.income
                : TransactionType.expense,
            date: DateTime.parse(transactionData['date'] as String),
            category: transactionData['category'] as String,
          );
          transactions.add(transaction);
        } catch (e) {
          // Skip invalid transaction
          continue;
        }
      }

      if (transactions.isEmpty) {
        _showSnackBar(
          context,
          'Tidak ada transaksi valid dalam file',
          Colors.red,
        );
        return;
      }

      // Clear existing data and import new data
      await LocalStorageService.clearAllTransactions();

      for (final transaction in transactions) {
        await LocalStorageService.addTransaction(transaction);
      }

      _showSnackBar(
        context,
        'Data berhasil di-import! ${transactions.length} transaksi',
        Colors.green,
      );

      // Navigate back to refresh home screen
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showSnackBar(context, 'Gagal import data: $e', Colors.red);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Konfirmasi Import'),
              content: const Text(
                'Import data akan mengganti semua transaksi yang ada. '
                'Apakah Anda yakin ingin melanjutkan?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Ya, Import'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/transaction.dart';
import '../database/migration_handler.dart';
import '../database/database_version.dart';
import '../validation/data_validator.dart';

class LocalStorageService {
  static Box<Transaction>? _transactionBox;
  static bool _isInitialized = false;

  static Future<void> initHive() async {
    try {
      if (!kIsWeb) {
        final appDocumentDir = await getApplicationDocumentsDirectory();
        Hive.init(appDocumentDir.path);
      }
      await Hive.initFlutter();
      
      // Check data compatibility before proceeding
      final isCompatible = await MigrationHandler.isDataCompatible();
      if (!isCompatible) {
        throw Exception('Database version is not compatible with this app version');
      }
      
      // Check if adapters are already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(TransactionTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TransactionAdapter());
      }
      
      _transactionBox = await Hive.openBox<Transaction>('transactions');
      
      // Handle database migrations
      await MigrationHandler.handleMigrations();
      
      _isInitialized = true;
      
      debugPrint('Hive initialized successfully with database version ${DatabaseVersion.currentVersion}');
    } catch (e, stackTrace) {
      debugPrint('Error initializing Hive: $e');
      debugPrint('Stack trace: $stackTrace');
      _isInitialized = false;
      rethrow;
    }
  }

  static bool get isInitialized => _isInitialized;

  static Box<Transaction>? get _box {
    if (!_isInitialized || _transactionBox == null) {
      debugPrint('Warning: Hive not initialized or box is null');
      return null;
    }
    return _transactionBox;
  }

  static Future<void> addTransaction(Transaction transaction) async {
    try {
      final box = _box;
      if (box == null) {
        throw Exception('Storage not initialized');
      }
      
      // Validate transaction before saving
      final validationResult = DataValidator.validateTransaction(transaction);
      if (!validationResult.isValid) {
        throw Exception('Invalid transaction data: ${validationResult.errors.join(', ')}');
      }
      
      // Sanitize transaction data
      final sanitizedTransaction = DataValidator.sanitizeTransaction(transaction);
      
      await box.add(sanitizedTransaction);
      debugPrint('Transaction added successfully');
    } catch (e, stackTrace) {
      debugPrint('Error adding transaction: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<List<Transaction>> getAllTransactions() async {
    try {
      final box = _box;
      if (box == null) {
        debugPrint('Storage not initialized, returning empty list');
        return [];
      }
      final transactions = box.values.toList();
      
      // Validate data integrity
      final integrityResult = await DataValidator.validateDataIntegrity(transactions);
      if (!integrityResult.isValid) {
        debugPrint('Data integrity issues found: ${integrityResult.issues}');
        // Log issues but don't block data retrieval
      }
      
      transactions.sort((a, b) => b.date.compareTo(a.date));
      debugPrint('Retrieved ${transactions.length} transactions');
      return transactions;
    } catch (e, stackTrace) {
      debugPrint('Error getting transactions: $e');
      debugPrint('Stack trace: $stackTrace');
      return []; // Return empty list instead of crashing
    }
  }

  static Future<void> deleteTransaction(dynamic key) async {
    try {
      final box = _box;
      if (box == null) {
        throw Exception('Storage not initialized');
      }
      await box.delete(key);
      debugPrint('Transaction deleted successfully');
    } catch (e, stackTrace) {
      debugPrint('Error deleting transaction: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> clearAllTransactions() async {
    try {
      final box = _box;
      if (box == null) {
        throw Exception('Storage not initialized');
      }
      await box.clear();
      debugPrint('All transactions cleared successfully');
    } catch (e, stackTrace) {
      debugPrint('Error clearing transactions: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

import 'package:flutter/foundation.dart';
import '../models/transaction.dart';

class DataValidator {
  /// Validates a single transaction
  static ValidationResult validateTransaction(Transaction transaction) {
    final errors = <String>[];
    
    // Validate ID
    if (transaction.id.isEmpty) {
      errors.add('Transaction ID cannot be empty');
    }
    
    // Validate title
    if (transaction.title.trim().isEmpty) {
      errors.add('Transaction title cannot be empty');
    }
    
    if (transaction.title.length > 100) {
      errors.add('Transaction title cannot exceed 100 characters');
    }
    
    // Validate amount
    if (transaction.amount <= 0) {
      errors.add('Transaction amount must be greater than 0');
    }
    
    if (transaction.amount > 999999999) {
      errors.add('Transaction amount is too large');
    }
    
    // Validate date
    final now = DateTime.now();
    final maxPastDate = now.subtract(const Duration(days: 365 * 10)); // 10 years ago
    final maxFutureDate = now.add(const Duration(days: 365)); // 1 year future
    
    if (transaction.date.isBefore(maxPastDate)) {
      errors.add('Transaction date cannot be more than 10 years ago');
    }
    
    if (transaction.date.isAfter(maxFutureDate)) {
      errors.add('Transaction date cannot be more than 1 year in the future');
    }
    
    // Validate category
    if (transaction.category.trim().isEmpty) {
      errors.add('Transaction category cannot be empty');
    }
    
    if (transaction.category.length > 50) {
      errors.add('Transaction category cannot exceed 50 characters');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
  
  /// Validates a list of transactions
  static BatchValidationResult validateTransactions(List<Transaction> transactions) {
    final results = <int, ValidationResult>{};
    var validCount = 0;
    var invalidCount = 0;
    
    for (int i = 0; i < transactions.length; i++) {
      final result = validateTransaction(transactions[i]);
      results[i] = result;
      
      if (result.isValid) {
        validCount++;
      } else {
        invalidCount++;
      }
    }
    
    return BatchValidationResult(
      totalCount: transactions.length,
      validCount: validCount,
      invalidCount: invalidCount,
      results: results,
    );
  }
  
  /// Validates transaction data integrity
  static Future<DataIntegrityResult> validateDataIntegrity(List<Transaction> transactions) async {
    final issues = <String>[];
    final duplicateIds = <String>[];
    final seenIds = <String>{};
    
    // Check for duplicate IDs
    for (final transaction in transactions) {
      if (seenIds.contains(transaction.id)) {
        duplicateIds.add(transaction.id);
        issues.add('Duplicate transaction ID found: ${transaction.id}');
      } else {
        seenIds.add(transaction.id);
      }
    }
    
    // Check for data consistency
    var totalIncome = 0.0;
    var totalExpense = 0.0;
    
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    }
    
    // Log statistics for monitoring
    debugPrint('Data Integrity Check:');
    debugPrint('Total transactions: ${transactions.length}');
    debugPrint('Total income: \$${totalIncome.toStringAsFixed(2)}');
    debugPrint('Total expense: \$${totalExpense.toStringAsFixed(2)}');
    debugPrint('Net balance: \$${(totalIncome - totalExpense).toStringAsFixed(2)}');
    debugPrint('Duplicate IDs found: ${duplicateIds.length}');
    
    return DataIntegrityResult(
      isValid: issues.isEmpty,
      issues: issues,
      duplicateIds: duplicateIds,
      totalTransactions: transactions.length,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );
  }
  
  /// Sanitizes transaction data
  static Transaction sanitizeTransaction(Transaction transaction) {
    return Transaction(
      id: transaction.id.trim(),
      title: transaction.title.trim(),
      amount: double.parse(transaction.amount.toStringAsFixed(2)), // Round to 2 decimal places
      date: transaction.date,
      type: transaction.type,
      category: transaction.category.trim(),
    );
  }
  
  /// Validates imported JSON data structure
  static ValidationResult validateImportData(Map<String, dynamic> data) {
    final errors = <String>[];
    
    // Check required fields
    final requiredFields = ['id', 'title', 'amount', 'date', 'type', 'category'];
    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        errors.add('Missing required field: $field');
      }
    }
    
    // Validate field types
    if (data['id'] != null && data['id'] is! String) {
      errors.add('Field "id" must be a string');
    }
    
    if (data['title'] != null && data['title'] is! String) {
      errors.add('Field "title" must be a string');
    }
    
    if (data['amount'] != null && data['amount'] is! num) {
      errors.add('Field "amount" must be a number');
    }
    
    if (data['date'] != null && data['date'] is! String) {
      errors.add('Field "date" must be a string');
    }
    
    if (data['type'] != null && data['type'] is! String) {
      errors.add('Field "type" must be a string');
    }
    
    if (data['category'] != null && data['category'] is! String) {
      errors.add('Field "category" must be a string');
    }
    
    // Validate enum values
    if (data['type'] != null && !['income', 'expense'].contains(data['type'])) {
      errors.add('Field "type" must be either "income" or "expense"');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  
  ValidationResult({
    required this.isValid,
    required this.errors,
  });
}

class BatchValidationResult {
  final int totalCount;
  final int validCount;
  final int invalidCount;
  final Map<int, ValidationResult> results;
  
  BatchValidationResult({
    required this.totalCount,
    required this.validCount,
    required this.invalidCount,
    required this.results,
  });
  
  bool get isAllValid => invalidCount == 0;
  double get validPercentage => totalCount > 0 ? (validCount / totalCount) * 100 : 0;
}

class DataIntegrityResult {
  final bool isValid;
  final List<String> issues;
  final List<String> duplicateIds;
  final int totalTransactions;
  final double totalIncome;
  final double totalExpense;
  
  DataIntegrityResult({
    required this.isValid,
    required this.issues,
    required this.duplicateIds,
    required this.totalTransactions,
    required this.totalIncome,
    required this.totalExpense,
  });
  
  double get netBalance => totalIncome - totalExpense;
}
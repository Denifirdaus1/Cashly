import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum ErrorType {
  network,
  storage,
  validation,
  migration,
  compatibility,
  unknown,
}

class AppError {
  final ErrorType type;
  final String message;
  final String? details;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final String? userAction;
  
  AppError({
    required this.type,
    required this.message,
    this.details,
    this.stackTrace,
    this.userAction,
  }) : timestamp = DateTime.now();
  
  @override
  String toString() {
    return 'AppError(type: $type, message: $message, timestamp: $timestamp)';
  }
}

class ErrorHandler {
  static final List<AppError> _errorLog = [];
  static const int maxLogSize = 100;
  
  /// Handles and logs errors
  static void handleError(AppError error) {
    // Add to error log
    _errorLog.add(error);
    
    // Keep log size manageable
    if (_errorLog.length > maxLogSize) {
      _errorLog.removeAt(0);
    }
    
    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint('=== APP ERROR ===');
      debugPrint('Type: ${error.type}');
      debugPrint('Message: ${error.message}');
      if (error.details != null) {
        debugPrint('Details: ${error.details}');
      }
      if (error.userAction != null) {
        debugPrint('User Action: ${error.userAction}');
      }
      debugPrint('Timestamp: ${error.timestamp}');
      if (error.stackTrace != null) {
        debugPrint('Stack Trace: ${error.stackTrace}');
      }
      debugPrint('================');
    }
    
    // TODO: Send to crash reporting service in production
    // _sendToCrashlytics(error);
  }
  
  /// Creates error from exception
  static AppError fromException(Exception exception, {
    ErrorType? type,
    String? userAction,
    StackTrace? stackTrace,
  }) {
    ErrorType errorType = type ?? _determineErrorType(exception);
    
    return AppError(
      type: errorType,
      message: exception.toString(),
      details: _getErrorDetails(exception),
      stackTrace: stackTrace,
      userAction: userAction,
    );
  }
  
  /// Determines error type from exception
  static ErrorType _determineErrorType(Exception exception) {
    final message = exception.toString().toLowerCase();
    
    if (message.contains('hive') || message.contains('storage') || message.contains('database')) {
      return ErrorType.storage;
    }
    
    if (message.contains('validation') || message.contains('invalid')) {
      return ErrorType.validation;
    }
    
    if (message.contains('migration')) {
      return ErrorType.migration;
    }
    
    if (message.contains('compatibility') || message.contains('version')) {
      return ErrorType.compatibility;
    }
    
    if (message.contains('network') || message.contains('connection')) {
      return ErrorType.network;
    }
    
    return ErrorType.unknown;
  }
  
  /// Gets additional error details
  static String? _getErrorDetails(Exception exception) {
    // Add specific error details based on exception type
    return null;
  }
  
  /// Gets user-friendly error message
  static String getUserFriendlyMessage(AppError error) {
    switch (error.type) {
      case ErrorType.storage:
        return 'Terjadi masalah saat menyimpan data. Silakan coba lagi.';
      case ErrorType.validation:
        return 'Data yang dimasukkan tidak valid. Periksa kembali input Anda.';
      case ErrorType.migration:
        return 'Sedang memperbarui struktur data. Mohon tunggu sebentar.';
      case ErrorType.compatibility:
        return 'Versi data tidak kompatibel. Silakan perbarui aplikasi.';
      case ErrorType.network:
        return 'Tidak dapat terhubung ke internet. Periksa koneksi Anda.';
      case ErrorType.unknown:
      default:
        return 'Terjadi kesalahan yang tidak diketahui. Silakan coba lagi.';
    }
  }
  
  /// Shows error dialog to user
  static void showErrorDialog(BuildContext context, AppError error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terjadi Kesalahan'),
        content: Text(getUserFriendlyMessage(error)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (kDebugMode)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showErrorDetails(context, error);
              },
              child: const Text('Detail'),
            ),
        ],
      ),
    );
  }
  
  /// Shows detailed error information (debug mode only)
  static void _showErrorDetails(BuildContext context, AppError error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error Details (${error.type})'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Message: ${error.message}'),
              const SizedBox(height: 8),
              Text('Timestamp: ${error.timestamp}'),
              if (error.details != null) ...[
                const SizedBox(height: 8),
                Text('Details: ${error.details}'),
              ],
              if (error.userAction != null) ...[
                const SizedBox(height: 8),
                Text('User Action: ${error.userAction}'),
              ],
              if (error.stackTrace != null) ...[
                const SizedBox(height: 8),
                const Text('Stack Trace:'),
                Text(
                  error.stackTrace.toString(),
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  /// Gets error log for debugging
  static List<AppError> getErrorLog() {
    return List.unmodifiable(_errorLog);
  }
  
  /// Clears error log
  static void clearErrorLog() {
    _errorLog.clear();
  }
  
  /// Gets error statistics
  static Map<ErrorType, int> getErrorStatistics() {
    final stats = <ErrorType, int>{};
    
    for (final error in _errorLog) {
      stats[error.type] = (stats[error.type] ?? 0) + 1;
    }
    
    return stats;
  }
  
  /// Checks if there are critical errors
  static bool hasCriticalErrors() {
    return _errorLog.any((error) => 
        error.type == ErrorType.storage || 
        error.type == ErrorType.migration ||
        error.type == ErrorType.compatibility
    );
  }
}
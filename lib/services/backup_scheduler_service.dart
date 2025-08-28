import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'google_drive_service.dart';

class BackupSchedulerService {
  static const String _backupTaskName = 'auto_backup_task';
  static const String _backupTaskTag = 'cashly_auto_backup';
  static const Duration _backupInterval = Duration(hours: 3);
  
  /// Initialize the background task scheduler
  static Future<void> initialize() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      debugPrint('BackupSchedulerService initialized');
    } catch (e) {
      debugPrint('Error initializing BackupSchedulerService: $e');
    }
  }
  
  /// Start automatic backup scheduling
  static Future<void> startAutoBackup() async {
    try {
      // Cancel any existing backup tasks
      await stopAutoBackup();
      
      // Register periodic backup task
      await Workmanager().registerPeriodicTask(
        _backupTaskName,
        _backupTaskName,
        frequency: _backupInterval,
        tag: _backupTaskTag,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 15),
      );
      
      debugPrint('Auto backup scheduled every ${_backupInterval.inHours} hours');
    } catch (e) {
      debugPrint('Error starting auto backup: $e');
    }
  }
  
  /// Stop automatic backup scheduling
  static Future<void> stopAutoBackup() async {
    try {
      await Workmanager().cancelByTag(_backupTaskTag);
      debugPrint('Auto backup stopped');
    } catch (e) {
      debugPrint('Error stopping auto backup: $e');
    }
  }
  
  /// Check if auto backup is currently scheduled
  static Future<bool> isAutoBackupScheduled() async {
    try {
      // This is a simplified check - WorkManager doesn't provide direct API to check scheduled tasks
      // We'll rely on our own preference tracking
      return await GoogleDriveService.isAutoBackupEnabled();
    } catch (e) {
      debugPrint('Error checking auto backup status: $e');
      return false;
    }
  }
  
  /// Perform immediate backup
  static Future<bool> performImmediateBackup() async {
    return await GoogleDriveService.performBackup();
  }
}

/// Background task callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('Background backup task started: $task');
      
      switch (task) {
        case BackupSchedulerService._backupTaskName:
          // Check if auto backup is still enabled
          final prefs = await SharedPreferences.getInstance();
          final isEnabled = prefs.getBool('auto_backup_enabled') ?? false;
          
          if (!isEnabled) {
            debugPrint('Auto backup is disabled, skipping');
            return Future.value(true);
          }
          
          // Perform backup
          final success = await GoogleDriveService.performBackup();
          
          if (success) {
            debugPrint('Background backup completed successfully');
            
            // Update backup statistics
            final backupCount = prefs.getInt('total_backups') ?? 0;
            await prefs.setInt('total_backups', backupCount + 1);
            await prefs.setInt('last_successful_backup', DateTime.now().millisecondsSinceEpoch);
          } else {
            debugPrint('Background backup failed');
            
            // Track failed backups
            final failedCount = prefs.getInt('failed_backups') ?? 0;
            await prefs.setInt('failed_backups', failedCount + 1);
            await prefs.setInt('last_failed_backup', DateTime.now().millisecondsSinceEpoch);
          }
          
          return Future.value(success);
          
        default:
          debugPrint('Unknown background task: $task');
          return Future.value(false);
      }
    } catch (e) {
      debugPrint('Error in background task: $e');
      return Future.value(false);
    }
  });
}

/// Backup statistics helper
class BackupStats {
  static Future<Map<String, dynamic>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'totalBackups': prefs.getInt('total_backups') ?? 0,
      'failedBackups': prefs.getInt('failed_backups') ?? 0,
      'lastSuccessfulBackup': prefs.getInt('last_successful_backup'),
      'lastFailedBackup': prefs.getInt('last_failed_backup'),
      'isAutoBackupEnabled': prefs.getBool('auto_backup_enabled') ?? false,
    };
  }
  
  static Future<void> resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('total_backups');
    await prefs.remove('failed_backups');
    await prefs.remove('last_successful_backup');
    await prefs.remove('last_failed_backup');
  }
}
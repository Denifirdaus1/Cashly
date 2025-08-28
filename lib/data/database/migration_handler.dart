import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import 'database_version.dart';

class MigrationHandler {
  static Future<void> handleMigrations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentDbVersion = prefs.getInt(DatabaseVersion.versionKey) ?? 0;
      
      if (currentDbVersion < DatabaseVersion.currentVersion) {
        debugPrint('Database migration needed: v$currentDbVersion -> v${DatabaseVersion.currentVersion}');
        
        // Perform migrations step by step
        for (int version = currentDbVersion + 1; version <= DatabaseVersion.currentVersion; version++) {
          await _migrateToVersion(version);
          debugPrint('Migrated to database version $version');
        }
        
        // Update version in preferences
        await prefs.setInt(DatabaseVersion.versionKey, DatabaseVersion.currentVersion);
        debugPrint('Database migration completed successfully');
      } else {
        debugPrint('Database is up to date (v${DatabaseVersion.currentVersion})');
      }
    } catch (e, stackTrace) {
      debugPrint('Error during database migration: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  static Future<void> _migrateToVersion(int version) async {
    switch (version) {
      case 1:
        // Initial version - no migration needed
        break;
        
      // Future migrations should be added here:
      // case 2:
      //   await _migrateToV2();
      //   break;
      // case 3:
      //   await _migrateToV3();
      //   break;
      
      default:
        debugPrint('Unknown migration version: $version');
    }
  }
  
  // Example migration methods for future versions:
  // static Future<void> _migrateToV2() async {
  //   // Example: Add description field to existing transactions
  //   final box = Hive.box<Transaction>('transactions');
  //   // Migration logic here
  // }
  
  static Future<bool> isDataCompatible() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dbVersion = prefs.getInt(DatabaseVersion.versionKey) ?? 0;
      
      // Check if current app version can handle the database version
      return dbVersion <= DatabaseVersion.currentVersion;
    } catch (e) {
      debugPrint('Error checking data compatibility: $e');
      return false;
    }
  }
  
  static Future<void> backupData() async {
    try {
      // Create backup before migration
      final box = Hive.box<Transaction>('transactions');
      final transactions = box.values.toList();
      
      // Store backup with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupBox = await Hive.openBox('backup_$timestamp');
      
      for (int i = 0; i < transactions.length; i++) {
        await backupBox.put(i, {
          'id': transactions[i].id,
          'title': transactions[i].title,
          'amount': transactions[i].amount,
          'date': transactions[i].date.toIso8601String(),
          'type': transactions[i].type.toString(),
          'category': transactions[i].category,
        });
      }
      
      await backupBox.close();
      debugPrint('Data backup created: backup_$timestamp');
    } catch (e) {
      debugPrint('Error creating data backup: $e');
    }
  }
}
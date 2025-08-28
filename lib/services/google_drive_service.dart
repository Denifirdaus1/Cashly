import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/transaction.dart';
import '../data/storage/local_storage.dart';

// Add missing import for googleapis_auth
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

class GoogleDriveService {
  static const String _backupFolderName = 'Cashly_Backups';
  static const String _lastBackupKey = 'last_backup_time';
  static const String _driveSetupKey = 'google_drive_setup';
  static const String _backupEnabledKey = 'auto_backup_enabled';
  
  // Web Client ID from Google Console
  static const String _webClientId = '569414803615-jpqghf721fak6vsjovep0m1udg9r6sf6.apps.googleusercontent.com';
  
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
    scopes: [
      drive.DriveApi.driveFileScope,
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );
  
  static drive.DriveApi? _driveApi;
  static String? _backupFolderId;
  
  /// Check if Google Drive is set up and connected
  static Future<bool> isSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_driveSetupKey) ?? false;
  }
  
  /// Check if auto backup is enabled
  static Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_backupEnabledKey) ?? false;
  }
  
  /// Set auto backup enabled/disabled
  static Future<void> setAutoBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backupEnabledKey, enabled);
  }
  
  /// Initialize Google Drive connection
  static Future<bool> initializeGoogleDrive() async {
    try {
      // Check if Google Services are available
      if (_webClientId == 'YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com') {
        debugPrint('Google Drive setup incomplete: Web Client ID not configured');
        return false;
      }
      
      GoogleSignInAccount? account;
      
      // Try silent sign in first
      account = await _googleSignIn.signInSilently();
      
      // If silent sign in fails, try regular sign in
      if (account == null) {
        if (kIsWeb) {
          // For web, show a more user-friendly message
          debugPrint('Please allow popup for Google Sign In');
        }
        account = await _googleSignIn.signIn();
      }
      
      if (account == null) {
        debugPrint('Google Sign In cancelled by user');
        return false;
      }
      
      final GoogleSignInAuthentication auth = await account.authentication;
      final credentials = AccessCredentials(
        AccessToken('Bearer', auth.accessToken!, DateTime.now().add(const Duration(hours: 1))),
        auth.idToken,
        [drive.DriveApi.driveFileScope],
      );
      
      final client = authenticatedClient(http.Client(), credentials);
      _driveApi = drive.DriveApi(client);
      
      // Create backup folder if it doesn't exist
      await _createBackupFolder();
      
      // Mark as setup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_driveSetupKey, true);
      await prefs.setBool(_backupEnabledKey, true);
      
      debugPrint('Google Drive initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error initializing Google Drive: $e');
      return false;
    }
  }
  
  /// Create backup folder in Google Drive
  static Future<void> _createBackupFolder() async {
    if (_driveApi == null) return;
    
    try {
      // Check if folder already exists
      final query = "name='$_backupFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final fileList = await _driveApi!.files.list(q: query);
      
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        _backupFolderId = fileList.files!.first.id;
        debugPrint('Backup folder found: $_backupFolderId');
        return;
      }
      
      // Create new folder
      final folder = drive.File()
        ..name = _backupFolderName
        ..mimeType = 'application/vnd.google-apps.folder';
      
      final createdFolder = await _driveApi!.files.create(folder);
      _backupFolderId = createdFolder.id;
      debugPrint('Backup folder created: $_backupFolderId');
    } catch (e) {
      debugPrint('Error creating backup folder: $e');
    }
  }
  
  /// Perform backup to Google Drive
  static Future<bool> performBackup() async {
    try {
      if (!await isSetup() || !await isAutoBackupEnabled()) {
        debugPrint('Google Drive not setup or auto backup disabled');
        return false;
      }
      
      // Re-authenticate if needed
      if (_driveApi == null) {
        final account = await _googleSignIn.signInSilently();
        if (account == null) {
          debugPrint('Failed to sign in silently');
          return false;
        }
        
        final auth = await account.authentication;
        final credentials = AccessCredentials(
          AccessToken('Bearer', auth.accessToken!, DateTime.now().add(const Duration(hours: 1))),
          auth.idToken,
          [drive.DriveApi.driveFileScope],
        );
        
        final client = authenticatedClient(http.Client(), credentials);
        _driveApi = drive.DriveApi(client);
        
        if (_backupFolderId == null) {
          await _createBackupFolder();
        }
      }
      
      // Get all transactions
      final transactions = await LocalStorageService.getAllTransactions();
      
      // Create backup data
      final backupData = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'transactions': transactions.map((t) => {
          'id': t.id,
          'title': t.title,
          'amount': t.amount,
          'date': t.date.toIso8601String(),
          'type': t.type.name,
          'category': t.category,
        }).toList(),
      };
      
      final jsonData = jsonEncode(backupData);
      final fileName = 'cashly_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      
      // Create file in Google Drive
      final file = drive.File()
        ..name = fileName
        ..parents = _backupFolderId != null ? [_backupFolderId!] : null;
      
      final media = drive.Media(Stream.value(utf8.encode(jsonData)), jsonData.length);
      await _driveApi!.files.create(file, uploadMedia: media);
      
      // Update last backup time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastBackupKey, DateTime.now().millisecondsSinceEpoch);
      
      debugPrint('Backup completed successfully: $fileName');
      return true;
    } catch (e) {
      debugPrint('Error performing backup: $e');
      return false;
    }
  }
  
  /// Get last backup time
  static Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastBackupKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
  
  /// List available backups
  static Future<List<Map<String, dynamic>>> listBackups() async {
    try {
      if (_driveApi == null || _backupFolderId == null) {
        return [];
      }
      
      final query = "parents in '$_backupFolderId' and name contains 'cashly_backup_' and trashed=false";
      final fileList = await _driveApi!.files.list(
        q: query,
        orderBy: 'createdTime desc',
        $fields: 'files(id,name,createdTime,size)',
      );
      
      return fileList.files?.map((file) => {
        'id': file.id,
        'name': file.name,
        'createdTime': file.createdTime?.toIso8601String(),
        'size': file.size,
      }).toList() ?? [];
    } catch (e) {
      debugPrint('Error listing backups: $e');
      return [];
    }
  }
  
  /// Restore from backup
  static Future<bool> restoreFromBackup(String fileId) async {
    try {
      if (_driveApi == null) {
        debugPrint('Google Drive API not initialized');
        return false;
      }
      
      final media = await _driveApi!.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      final bytes = await media.stream.toList();
      final jsonData = utf8.decode(bytes.expand((x) => x).toList());
      
      // Validate JSON format
      final backupData = jsonDecode(jsonData);
      
      // Validate backup data structure
      if (!_validateBackupFormat(backupData)) {
        debugPrint('Invalid backup format detected');
        return false;
      }
      
      // Clear existing transactions
      await LocalStorageService.clearAllTransactions();
      
      // Restore transactions
      final transactions = backupData['transactions'] as List;
      for (final txData in transactions) {
        try {
          final transaction = Transaction(
            id: txData['id'] ?? '',
            title: txData['title'] ?? 'Unknown',
            amount: (txData['amount'] as num?)?.toDouble() ?? 0.0,
            date: DateTime.tryParse(txData['date'] ?? '') ?? DateTime.now(),
            type: txData['type'] == 'income' ? TransactionType.income : TransactionType.expense,
            category: txData['category'] ?? 'Other',
          );
          await LocalStorageService.addTransaction(transaction);
        } catch (e) {
          debugPrint('Error processing transaction: $e');
          // Continue with next transaction instead of failing completely
        }
      }
      
      debugPrint('Restore completed successfully');
      return true;
    } catch (e) {
      debugPrint('Error restoring from backup: $e');
      return false;
    }
  }
  
  /// Validate backup data format
  static bool _validateBackupFormat(Map<String, dynamic> backupData) {
    try {
      // Check required fields
      if (!backupData.containsKey('version') || 
          !backupData.containsKey('timestamp') || 
          !backupData.containsKey('transactions')) {
        return false;
      }
      
      // Check transactions format
      final transactions = backupData['transactions'];
      if (transactions is! List) {
        return false;
      }
      
      // Validate each transaction has required fields
      for (final tx in transactions) {
        if (tx is! Map<String, dynamic>) {
          return false;
        }
        
        // Check required transaction fields
        if (!tx.containsKey('id') || 
            !tx.containsKey('title') || 
            !tx.containsKey('amount') || 
            !tx.containsKey('date') || 
            !tx.containsKey('type')) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error validating backup format: $e');
      return false;
    }
  }
  
  /// Disconnect Google Drive
  static Future<void> disconnect() async {
    try {
      await _googleSignIn.signOut();
      _driveApi = null;
      _backupFolderId = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_driveSetupKey, false);
      await prefs.setBool(_backupEnabledKey, false);
      
      debugPrint('Google Drive disconnected');
    } catch (e) {
      debugPrint('Error disconnecting Google Drive: $e');
    }
  }
}
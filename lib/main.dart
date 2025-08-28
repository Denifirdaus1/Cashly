import 'package:flutter/material.dart';
import 'package:cash_inout_app/data/storage/local_storage.dart';
import 'package:cash_inout_app/features/add_transaction/add_transaction_viewmodel.dart';
import 'package:cash_inout_app/features/home/home_screen.dart';
import 'package:cash_inout_app/features/home/home_viewmodel.dart';
import 'package:cash_inout_app/features/report/chart_viewmodel.dart';
import 'package:cash_inout_app/features/setup/google_drive_setup_screen.dart';
import 'package:cash_inout_app/services/widget_service.dart';
import 'package:cash_inout_app/services/backup_scheduler_service.dart';
import 'package:cash_inout_app/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cash_inout_app/core/error/error_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    final error = AppError(
      type: ErrorType.unknown,
      message: details.exception.toString(),
      details: details.context?.toString(),
      stackTrace: details.stack,
      userAction: 'App runtime error',
    );
    ErrorHandler.handleError(error);
  };
  
  try {
    // Initialize locale data for Indonesian formatting
    await initializeDateFormatting('id_ID', null);
    
    // Initialize Hive with error handling
    await LocalStorageService.initHive();
    
    // Initialize widget service
    await WidgetService.initializeWidget();
    
    // Initialize backup scheduler service
    await BackupSchedulerService.initialize();
    
    // Check if this is first time install
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = !prefs.containsKey('first_time_setup_done');

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => HomeViewModel()),
          ChangeNotifierProvider(create: (_) => AddTransactionViewModel()),
          ChangeNotifierProvider(
            create: (_) => ChartViewModel(LocalStorageService()),
          ),
        ],
        child: MyApp(isFirstTime: isFirstTime),
      ),
    );
  } catch (e, stackTrace) {
    final error = AppError(
      type: ErrorHandler.fromException(Exception(e.toString())).type,
      message: 'App initialization failed: $e',
      stackTrace: stackTrace,
      userAction: 'App startup',
    );
    ErrorHandler.handleError(error);
    
    // Run app with error state
    runApp(ErrorApp(error: error));
  }
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;
  
  const MyApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cash In/Out App',
      theme: AppTheme.lightTheme,
      home: isFirstTime 
          ? const GoogleDriveSetupScreen(isFirstTime: true)
          : const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ErrorApp extends StatelessWidget {
  final AppError error;
  
  const ErrorApp({super.key, required this.error});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cash In/Out App - Error',
      theme: ThemeData.light(),
      home: ErrorScreen(error: error),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final AppError error;
  
  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1E88E5),
              Color(0xFF42A5F5),
              Color(0xFF90CAF9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Oops! Terjadi Kesalahan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  ErrorHandler.getUserFriendlyMessage(error),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Restart aplikasi dengan exit dan restart
                    // Atau bisa menggunakan restart package
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E88E5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Restart Aplikasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ErrorHandler.showErrorDialog(context, error);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white70,
                      foregroundColor: const Color(0xFF1E88E5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Show Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

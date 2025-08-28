import 'package:flutter/material.dart';
import 'package:cash_inout_app/services/google_drive_service.dart';
import 'package:cash_inout_app/services/backup_scheduler_service.dart';
import 'package:cash_inout_app/features/home/home_screen.dart';

class GoogleDriveSetupScreen extends StatefulWidget {
  final bool isFirstTime;
  
  const GoogleDriveSetupScreen({super.key, this.isFirstTime = true});

  @override
  State<GoogleDriveSetupScreen> createState() => _GoogleDriveSetupScreenState();
}

class _GoogleDriveSetupScreenState extends State<GoogleDriveSetupScreen> {
  bool _isLoading = false;
  bool _isConnected = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
  }

  Future<void> _checkConnectionStatus() async {
    final isSetup = await GoogleDriveService.isSetup();
    setState(() {
      _isConnected = isSetup;
    });
  }

  Future<void> _connectToGoogleDrive() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await GoogleDriveService.initializeGoogleDrive();
      
      if (success) {
        // Start auto backup scheduling
        await BackupSchedulerService.startAutoBackup();
        
        setState(() {
          _isConnected = true;
          _isLoading = false;
        });
        
        if (widget.isFirstTime) {
          // Navigate to home screen after successful setup
          _navigateToHome();
        } else {
          // Show success message
          _showSuccessDialog();
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Setup Google Drive belum lengkap. Silakan ikuti panduan setup di GOOGLE_DRIVE_SETUP_GUIDE.md untuk mengkonfigurasi Google Console dan menambahkan google-services.json.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  Future<void> _skipSetup() async {
    if (widget.isFirstTime) {
      _navigateToHome();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Berhasil!'),
        content: const Text('Google Drive berhasil terhubung. Backup otomatis akan berjalan setiap 3 jam.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnect() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await GoogleDriveService.disconnect();
      await BackupSchedulerService.stopAutoBackup();
      
      setState(() {
        _isConnected = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memutuskan koneksi: $e';
      });
    }
  }

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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!widget.isFirstTime)
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                
                const Spacer(),
                
                // Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.cloud_upload,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Title
                Text(
                  widget.isFirstTime ? 'Selamat Datang!' : 'Google Drive Backup',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Text(
                  _isConnected
                      ? 'Google Drive sudah terhubung!\nBackup otomatis akan berjalan setiap 3 jam.'
                      : 'Hubungkan ke Google Drive untuk backup otomatis data Anda setiap 3 jam. Data Anda akan aman dan dapat dipulihkan kapan saja.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Features list
                if (!_isConnected) ..._buildFeaturesList(),
                
                const SizedBox(height: 32),
                
                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                // Action buttons
                if (_isConnected) ..._buildConnectedButtons() else ..._buildSetupButtons(),
                
                const Spacer(),
                
                // Skip button for first time setup
                if (widget.isFirstTime && !_isConnected)
                  TextButton(
                    onPressed: _isLoading ? null : _skipSetup,
                    child: const Text(
                      'Lewati untuk sekarang',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFeaturesList() {
    final features = [
      'Backup otomatis setiap 3 jam',
      'Data tersimpan aman di Google Drive',
      'Restore data kapan saja',
      'Sinkronisasi antar perangkat',
    ];

    return [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: features.map((feature) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    ];
  }

  List<Widget> _buildSetupButtons() {
    return [
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _connectToGoogleDrive,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1E88E5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
                  ),
                )
              : const Text(
                  'Hubungkan ke Google Drive',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    ];
  }

  List<Widget> _buildConnectedButtons() {
    return [
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _disconnect,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.withOpacity(0.8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Putuskan Koneksi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    ];
  }
}
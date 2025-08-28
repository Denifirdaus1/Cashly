import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cash_inout_app/services/google_drive_service.dart';
import 'package:cash_inout_app/services/backup_scheduler_service.dart';
import 'package:cash_inout_app/features/setup/google_drive_setup_screen.dart';

class BackupManagementScreen extends StatefulWidget {
  const BackupManagementScreen({super.key});

  @override
  State<BackupManagementScreen> createState() => _BackupManagementScreenState();
}

class _BackupManagementScreenState extends State<BackupManagementScreen> {
  bool _isLoading = true;
  bool _isConnected = false;
  bool _isAutoBackupEnabled = false;
  DateTime? _lastBackupTime;
  List<Map<String, dynamic>> _backups = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isConnected = await GoogleDriveService.isSetup();
      final isAutoEnabled = await GoogleDriveService.isAutoBackupEnabled();
      final lastBackup = await GoogleDriveService.getLastBackupTime();
      final stats = await BackupStats.getStats();
      
      List<Map<String, dynamic>> backups = [];
      if (isConnected) {
        backups = await GoogleDriveService.listBackups();
      }

      setState(() {
        _isConnected = isConnected;
        _isAutoBackupEnabled = isAutoEnabled;
        _lastBackupTime = lastBackup;
        _backups = backups;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Gagal memuat data backup: $e');
    }
  }

  Future<void> _toggleAutoBackup(bool enabled) async {
    try {
      await GoogleDriveService.setAutoBackupEnabled(enabled);
      
      if (enabled) {
        await BackupSchedulerService.startAutoBackup();
      } else {
        await BackupSchedulerService.stopAutoBackup();
      }
      
      setState(() {
        _isAutoBackupEnabled = enabled;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled ? 'Auto backup diaktifkan' : 'Auto backup dinonaktifkan',
          ),
          backgroundColor: enabled ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      _showErrorDialog('Gagal mengubah pengaturan auto backup: $e');
    }
  }

  Future<void> _performManualBackup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await BackupSchedulerService.performImmediateBackup();
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      } else {
        _showErrorDialog('Backup gagal. Silakan coba lagi.');
      }
    } catch (e) {
      _showErrorDialog('Terjadi kesalahan saat backup: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreFromBackup(String fileId, String fileName) async {
    final confirmed = await _showConfirmDialog(
      'Restore Backup',
      'Apakah Anda yakin ingin restore dari backup "$fileName"? Semua data saat ini akan diganti.',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await GoogleDriveService.restoreFromBackup(fileId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restore berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Return to previous screen
      } else {
        _showErrorDialog('Restore gagal. Silakan coba lagi.');
      }
    } catch (e) {
      _showErrorDialog('Terjadi kesalahan saat restore: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _formatFileSize(String? sizeStr) {
    if (sizeStr == null) return 'Unknown';
    final size = int.tryParse(sizeStr) ?? 0;
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Backup Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : !_isConnected
                ? _buildNotConnectedView()
                : _buildConnectedView(),
      ),
    );
  }

  Widget _buildNotConnectedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 80,
              color: Colors.white70,
            ),
            const SizedBox(height: 24),
            const Text(
              'Google Drive Tidak Terhubung',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Hubungkan ke Google Drive untuk menggunakan fitur backup otomatis.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const GoogleDriveSetupScreen(isFirstTime: false),
                    ),
                  ).then((_) => _loadData());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Hubungkan ke Google Drive',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedView() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildControlsCard(),
            const SizedBox(height: 16),
            _buildStatsCard(),
            const SizedBox(height: 16),
            _buildBackupsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Backup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.cloud_done,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                const Text('Google Drive: Terhubung'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _isAutoBackupEnabled ? Icons.schedule : Icons.schedule_outlined,
                  color: _isAutoBackupEnabled ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Auto Backup: ${_isAutoBackupEnabled ? "Aktif" : "Nonaktif"}',
                ),
              ],
            ),
            if (_lastBackupTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.backup, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Backup Terakhir: ${DateFormat('dd/MM/yyyy HH:mm').format(_lastBackupTime!)}',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlsCard() {
    return Card(
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kontrol Backup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto Backup (Setiap 3 Jam)'),
              subtitle: const Text('Backup otomatis akan berjalan di background'),
              value: _isAutoBackupEnabled,
              onChanged: _toggleAutoBackup,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _performManualBackup,
                icon: const Icon(Icons.backup),
                label: const Text('Backup Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistik Backup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Backup',
                  '${_stats['totalBackups'] ?? 0}',
                  Icons.backup,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Gagal',
                  '${_stats['failedBackups'] ?? 0}',
                  Icons.error,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBackupsCard() {
    return Card(
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daftar Backup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_backups.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'Belum ada backup tersedia',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _backups.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final backup = _backups[index];
                  return ListTile(
                    leading: const Icon(Icons.folder, color: Colors.blue),
                    title: Text(
                      backup['name'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tanggal: ${_formatDateTime(backup['createdTime'])}'),
                        Text('Ukuran: ${_formatFileSize(backup['size'])}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.restore, color: Colors.green),
                      onPressed: () => _restoreFromBackup(
                        backup['id'],
                        backup['name'] ?? 'Unknown',
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
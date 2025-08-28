# Fitur Auto Backup ke Google Drive

## Deskripsi
Fitur ini memungkinkan aplikasi Cash In/Out untuk secara otomatis melakukan backup data transaksi ke Google Drive setiap 3 jam. Fitur ini dirancang untuk memberikan keamanan data dan kemudahan bagi pengguna.

## Fitur Utama

### 1. Setup Awal (First Time Install)
- Saat pertama kali menginstall aplikasi, pengguna akan diminta untuk menghubungkan akun Google Drive
- Setup dilakukan melalui Google Sign-In yang aman
- Setelah berhasil terhubung, auto backup akan langsung aktif

### 2. Auto Backup Otomatis
- Backup dilakukan setiap 3 jam secara otomatis di background
- Menggunakan WorkManager untuk scheduling yang reliable
- Data yang dibackup dalam format JSON yang aman
- Backup disimpan dalam folder khusus "CashInOut_Backups" di Google Drive

### 3. Backup Management
- **Status Monitoring**: Melihat status koneksi Google Drive dan auto backup
- **Manual Backup**: Melakukan backup manual kapan saja
- **Backup History**: Melihat daftar semua backup yang tersedia
- **Restore Data**: Memulihkan data dari backup yang dipilih
- **Statistik**: Melihat jumlah backup yang berhasil dan gagal

### 4. Pengaturan Backup
- Toggle untuk mengaktifkan/menonaktifkan auto backup
- Informasi waktu backup terakhir
- Pengaturan koneksi Google Drive

## Cara Menggunakan

### Setup Pertama Kali
1. Buka aplikasi Cash In/Out
2. Pada layar setup Google Drive, tap "Hubungkan ke Google Drive"
3. Login dengan akun Google Anda
4. Berikan izin akses ke Google Drive
5. Setelah berhasil, Anda akan diarahkan ke halaman utama
6. Auto backup sudah aktif secara otomatis

### Mengelola Backup
1. Buka menu **Pengaturan**
2. Pilih **Backup Management**
3. Di sini Anda dapat:
   - Melihat status backup
   - Mengaktifkan/menonaktifkan auto backup
   - Melakukan backup manual
   - Melihat daftar backup
   - Restore dari backup

### Restore Data
1. Masuk ke **Backup Management**
2. Scroll ke bagian **Daftar Backup**
3. Pilih backup yang ingin direstore
4. Tap icon restore (hijau)
5. Konfirmasi restore
6. Data akan dipulihkan dan aplikasi akan restart

## Keamanan Data

### Enkripsi
- Data backup disimpan dalam format JSON yang aman
- Menggunakan Google Drive API yang terenkripsi
- Tidak ada data sensitif yang disimpan dalam plain text

### Privasi
- Aplikasi hanya mengakses folder backup yang dibuat khusus
- Tidak mengakses file lain di Google Drive Anda
- Data backup hanya dapat diakses oleh aplikasi ini

### Validasi Data
- Setiap backup divalidasi sebelum disimpan
- Restore data juga melalui proses validasi
- Backup yang corrupt akan ditolak

## Troubleshooting

### Auto Backup Tidak Berjalan
1. Pastikan koneksi internet stabil
2. Cek apakah Google Drive masih terhubung
3. Pastikan auto backup diaktifkan di pengaturan
4. Restart aplikasi jika diperlukan

### Gagal Backup Manual
1. Cek koneksi internet
2. Pastikan Google Drive tidak penuh
3. Coba disconnect dan connect ulang Google Drive
4. Restart aplikasi

### Gagal Restore
1. Pastikan file backup tidak corrupt
2. Cek koneksi internet
3. Pastikan ada cukup ruang penyimpanan lokal
4. Coba backup yang lain

## Persyaratan Sistem

### Android
- Android 6.0 (API level 23) atau lebih tinggi
- Koneksi internet
- Akun Google
- Google Drive dengan ruang penyimpanan tersedia

### Permissions
- Internet access
- Network state access
- Wake lock (untuk background backup)
- Boot completed (untuk restart backup setelah reboot)

## Batasan

### Platform
- Fitur auto backup hanya tersedia di platform Android
- Pada web/desktop, hanya backup manual yang tersedia

### Ukuran Data
- Backup optimal untuk data transaksi hingga 10,000 entries
- File backup biasanya berukuran < 1MB

### Frekuensi
- Auto backup setiap 3 jam (tidak dapat diubah)
- Manual backup dapat dilakukan kapan saja
- Maksimal 50 backup file disimpan (yang lama akan dihapus otomatis)

## Tips Penggunaan

1. **Backup Rutin**: Biarkan auto backup aktif untuk keamanan maksimal
2. **Manual Backup**: Lakukan backup manual sebelum update aplikasi
3. **Cek Berkala**: Periksa status backup secara berkala
4. **Ruang Drive**: Pastikan Google Drive memiliki ruang yang cukup
5. **Koneksi Stabil**: Gunakan WiFi untuk backup yang lebih reliable

## Update dan Maintenance

- Fitur backup akan terus diupdate untuk performa yang lebih baik
- Backup format kompatibel dengan versi aplikasi yang akan datang
- Statistik backup membantu monitoring kesehatan sistem

---

**Catatan**: Fitur ini dirancang untuk memberikan keamanan data maksimal. Namun, tetap disarankan untuk melakukan backup manual secara berkala sebagai langkah keamanan tambahan.
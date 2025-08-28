# Panduan Setup Google Drive untuk Aplikasi Cashly

## ❌ Masalah: "Gagal menghubungkan ke Google Drive"

Error ini terjadi karena konfigurasi Google Console dan OAuth belum lengkap. Berikut langkah-langkah untuk memperbaikinya:

## 🔧 Langkah 1: Setup Google Cloud Console

### 1.1 Buat Project di Google Cloud Console
1. Buka [Google Cloud Console](https://console.cloud.google.com/)
2. Klik **"Select a project"** → **"New Project"**
3. Nama project: `Cashly App` (atau nama lain)
4. Klik **"Create"**

### 1.2 Enable Google Drive API
1. Di Google Cloud Console, pilih project Anda
2. Buka **"APIs & Services"** → **"Library"**
3. Cari **"Google Drive API"**
4. Klik **"Enable"**

### 1.3 Enable Google Sign-In API
1. Masih di **"Library"**
2. Cari **"Google Sign-In API"** atau **"Google+ API"**
3. Klik **"Enable"**

## 🔧 Langkah 2: Konfigurasi OAuth Consent Screen

### 2.1 Setup OAuth Consent
1. Buka **"APIs & Services"** → **"OAuth consent screen"**
2. Pilih **"External"** → **"Create"**
3. Isi informasi berikut:
   - **App name**: `Cashly - Cash In/Out App`
   - **User support email**: Email Anda
   - **Developer contact email**: Email Anda
4. Klik **"Save and Continue"**

### 2.2 Tambahkan Scopes
1. Di tab **"Scopes"**, klik **"Add or Remove Scopes"**
2. Tambahkan scopes berikut:
   - `https://www.googleapis.com/auth/drive.file`
   - `https://www.googleapis.com/auth/userinfo.email`
   - `https://www.googleapis.com/auth/userinfo.profile`
3. Klik **"Update"** → **"Save and Continue"**

### 2.3 Test Users (Opsional untuk Development)
1. Di tab **"Test users"**, tambahkan email Anda
2. Klik **"Save and Continue"**

## 🔧 Langkah 3: Dapatkan SHA-1 Fingerprint

### 3.1 Generate SHA-1 untuk Debug
Buka terminal di folder project dan jalankan:

```bash
# Untuk Windows
cd android
.\gradlew signingReport

# Atau gunakan keytool langsung
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

### 3.2 Catat SHA-1 Fingerprint
Cari output seperti ini dan catat SHA-1:
```
Certificate fingerprints:
    SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
    SHA256: ...
```

## 🔧 Langkah 4: Buat OAuth 2.0 Credentials

### 4.1 Buat Credentials
1. Buka **"APIs & Services"** → **"Credentials"**
2. Klik **"+ Create Credentials"** → **"OAuth 2.0 Client IDs"**
3. **Application type**: `Android`
4. **Name**: `Cashly Android App`

### 4.2 Konfigurasi Android App
1. **Package name**: `com.example.cash_inout_app`
2. **SHA-1 certificate fingerprint**: Paste SHA-1 yang sudah dicatat
3. Klik **"Create"**

### 4.3 Buat Web Client (Untuk Google Sign-In)
1. Klik **"+ Create Credentials"** → **"OAuth 2.0 Client IDs"** lagi
2. **Application type**: `Web application`
3. **Name**: `Cashly Web Client`
4. Klik **"Create"**
5. **Catat Client ID** yang dihasilkan

## 🔧 Langkah 5: Download google-services.json

### 5.1 Buat Firebase Project (Alternatif)
Atau gunakan Firebase Console:
1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Klik **"Add project"**
3. Pilih project Google Cloud yang sudah dibuat
4. Tambahkan Android app dengan package name: `com.example.cash_inout_app`
5. Download **google-services.json**

### 5.2 Letakkan File
Copy file `google-services.json` ke:
```
c:\cash_inout_app\android\app\google-services.json
```

## 🔧 Langkah 6: Update Konfigurasi Android

### 6.1 Update build.gradle (Project Level)
File: `android/build.gradle.kts`
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.0" apply false
}
```

### 6.2 Update build.gradle (App Level)
File: `android/app/build.gradle.kts`
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Tambahkan ini
}
```

## 🔧 Langkah 7: Update Kode Aplikasi

### 7.1 Update GoogleDriveService
Tambahkan Web Client ID di file `lib/services/google_drive_service.dart`:

```dart
static const String _webClientId = 'YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com';

// Update method _signInToGoogle
Future<GoogleSignInAccount?> _signInToGoogle() async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: _webClientId, // Tambahkan ini
      scopes: [
        'https://www.googleapis.com/auth/drive.file',
        'https://www.googleapis.com/auth/userinfo.email',
      ],
    );
    
    return await googleSignIn.signIn();
  } catch (e) {
    print('Error signing in to Google: $e');
    return null;
  }
}
```

## 🔧 Langkah 8: Testing

### 8.1 Clean dan Rebuild
```bash
flutter clean
flutter pub get
flutter run
```

### 8.2 Test di Device
1. Pastikan device terhubung internet
2. Buka aplikasi Cashly
3. Coba hubungkan ke Google Drive
4. Pilih akun Google Anda
5. Berikan izin akses

## 🔧 Troubleshooting

### Error: "Sign in failed"
- Pastikan SHA-1 fingerprint benar
- Pastikan package name sama: `com.example.cash_inout_app`
- Pastikan google-services.json sudah di tempat yang benar

### Error: "API not enabled"
- Enable Google Drive API di Google Cloud Console
- Enable Google Sign-In API

### Error: "OAuth consent screen not configured"
- Lengkapi OAuth consent screen
- Tambahkan email Anda sebagai test user

### Error: "Invalid client"
- Pastikan Web Client ID benar di kode
- Pastikan Android Client sudah dibuat dengan SHA-1 yang benar

## 📋 Checklist Setup

- [ ] Project dibuat di Google Cloud Console
- [ ] Google Drive API enabled
- [ ] Google Sign-In API enabled
- [ ] OAuth consent screen dikonfigurasi
- [ ] SHA-1 fingerprint didapatkan
- [ ] Android OAuth client dibuat
- [ ] Web OAuth client dibuat
- [ ] google-services.json didownload dan ditempatkan
- [ ] build.gradle diupdate
- [ ] Web Client ID ditambahkan ke kode
- [ ] App di-rebuild dan ditest

## 🎯 Hasil yang Diharapkan

Setelah setup lengkap:
1. Aplikasi dapat terhubung ke Google Drive
2. User dapat login dengan akun Google
3. Backup otomatis berfungsi
4. Manual backup dan restore berfungsi

---

**Catatan Penting**: 
- Proses ini hanya perlu dilakukan sekali
- Untuk production, buat release keystore dan dapatkan SHA-1 untuk release
- Simpan semua credentials dengan aman
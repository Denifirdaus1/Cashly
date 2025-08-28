@echo off
echo ========================================
echo   MENDAPATKAN SHA-1 FINGERPRINT
echo ========================================
echo.
echo Metode 1: Menggunakan Gradle
echo ----------------------------
cd android
call gradlew signingReport
echo.
echo ========================================
echo Metode 2: Menggunakan Keytool Langsung
echo ========================================
echo.
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
echo.
echo ========================================
echo SELESAI!
echo ========================================
echo.
echo Catat SHA-1 fingerprint dari output di atas
echo dan gunakan untuk konfigurasi Google Console
echo.
pause
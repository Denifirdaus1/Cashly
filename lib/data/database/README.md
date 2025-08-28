# Database Versioning & Migration System

## Overview
Sistem ini memastikan kompatibilitas data antar versi aplikasi dan mencegah kehilangan data user saat update.

## Struktur Data Versi 1 (Current)
```dart
class Transaction {
  String id;
  String title;
  double amount;
  DateTime date;
  TransactionType type; // income, expense
  String category;
}

enum TransactionType {
  income,
  expense
}
```

## Cara Menambah Versi Baru

### 1. Update Database Version
```dart
// di database_version.dart
static const int currentVersion = 2; // increment version

static const Map<int, String> versionHistory = {
  1: 'Initial version with basic Transaction model',
  2: 'Added description field to Transaction', // tambah deskripsi
};
```

### 2. Buat Migration Logic
```dart
// di migration_handler.dart
case 2:
  await _migrateToV2();
  break;

static Future<void> _migrateToV2() async {
  // Logic untuk migrate data dari v1 ke v2
  final box = Hive.box<Transaction>('transactions');
  // Implementasi migration
}
```

### 3. Update Model (Jika Perlu)
- Jika menambah field baru, pastikan field lama tetap ada
- Gunakan default values untuk field baru
- Jangan hapus atau ubah tipe field yang sudah ada

## Prinsip Backward Compatibility

### ✅ BOLEH:
- Menambah field baru dengan default value
- Menambah enum value baru
- Menambah model baru
- Menambah method baru

### ❌ TIDAK BOLEH:
- Menghapus field yang sudah ada
- Mengubah tipe data field
- Mengubah nama field
- Menghapus enum value
- Mengubah struktur data yang sudah ada

## Contoh Migration yang Benar

### Menambah Field Baru:
```dart
// SEBELUM (v1)
class Transaction {
  String id;
  String title;
  double amount;
  DateTime date;
  TransactionType type;
  String category;
}

// SESUDAH (v2) - BENAR
class Transaction {
  String id;
  String title;
  double amount;
  DateTime date;
  TransactionType type;
  String category;
  String? description; // field baru dengan nullable
}
```

### Migration Logic:
```dart
static Future<void> _migrateToV2() async {
  final box = Hive.box<Transaction>('transactions');
  final transactions = box.values.toList();
  
  // Update semua transaction dengan field baru
  for (var transaction in transactions) {
    // Field lama tetap sama, field baru dapat default value
    if (transaction.description == null) {
      transaction.description = ''; // default value
      await transaction.save();
    }
  }
}
```

## Testing Migration

1. Test dengan data versi lama
2. Test migration process
3. Test rollback scenario
4. Test dengan data kosong
5. Test dengan data corrupt

## Backup Strategy

Sistem otomatis membuat backup sebelum migration:
- Backup disimpan dengan timestamp
- Format: `backup_[timestamp]`
- Dapat digunakan untuk recovery jika migration gagal

## Error Handling

- Jika migration gagal, data original tetap aman
- Error log detail untuk debugging
- Graceful fallback ke versi sebelumnya
- User notification jika diperlukan

## Monitoring

- Log setiap migration step
- Track migration performance
- Monitor error rates
- User feedback collection

---

**PENTING**: Selalu test migration dengan data production sebelum release!
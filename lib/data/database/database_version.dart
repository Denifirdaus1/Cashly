class DatabaseVersion {
  static const int currentVersion = 1;
  static const String versionKey = 'database_version';
  
  // Version history:
  // v1: Initial version with Transaction model (id, title, amount, date, type, category)
  
  static const Map<int, String> versionHistory = {
    1: 'Initial version with basic Transaction model',
  };
  
  // Future versions should be added here:
  // 2: 'Added description field to Transaction',
  // 3: 'Added Category model',
  // etc.
}
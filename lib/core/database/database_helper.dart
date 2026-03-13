import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('diamond_story_v1.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;
    if (kIsWeb) {
      // On web we use the logical path, sqflite_common_ffi_web maps this to IndexedDB
      path = filePath;
    } else {
      // Use getApplicationSupportDirectory to persist data across Windows app rebuilds reliably
      final appDir = await getApplicationSupportDirectory();
      path = join(appDir.path, filePath);
    }
    
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: _onOpen,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    final now = DateTime.now().toIso8601String();

    await db.execute('''
      CREATE TABLE rough_stones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lot_no TEXT UNIQUE NOT NULL,
        title TEXT,
        weight REAL,
        quality TEXT,
        purchase_price REAL,
        purchase_date TEXT,
        supplier_id INTEGER,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE diamonds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parent_lot TEXT,
        diamond_code TEXT UNIQUE NOT NULL,
        weight REAL,
        status TEXT DEFAULT 'raw',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE process_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        cost REAL DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE processes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        diamond_id INTEGER,
        process_type_id INTEGER,
        fee REAL DEFAULT 0,
        party_name TEXT,
        from_date TEXT,
        to_date TEXT,
        status TEXT DEFAULT 'pending',
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE parties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT,
        phone TEXT,
        address TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        party_id INTEGER,
        lot_id INTEGER,
        amount REAL,
        date TEXT,
        notes TEXT,
        auto_generated INTEGER DEFAULT 0,
        auto_source TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX idx_purchases_auto_rough_by_lot
      ON purchases(lot_id)
      WHERE auto_generated = 1 AND auto_source = 'rough_stone'
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        party_id INTEGER,
        diamond_id INTEGER,
        price REAL,
        date TEXT,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        party_id INTEGER,
        amount REAL,
        type TEXT,
        category TEXT,
        date TEXT,
        status TEXT DEFAULT 'pending',
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        app_password_hash TEXT,
        last_backup TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Seed default process types
    for (final name in ['Cutting', 'Polishing', 'Shining', 'Grading']) {
      await db.insert('process_types', {'name': name, 'cost': 0, 'created_at': now});
    }

    // Seed default expense categories
    for (final name in ['Rent', 'Electricity', 'Salary', 'Transport', 'Miscellaneous']) {
      await db.insert('expense_categories', {'name': name, 'created_at': now});
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _ensureProcessCostColumns(db);
    }
    if (oldVersion < 3) {
      await _ensurePurchaseAutoSyncColumns(db);
    }
  }

  Future<void> _onOpen(Database db) async {
    // Keep schema resilient even if users have older local DBs.
    await _ensureProcessCostColumns(db);
    await _ensurePurchaseAutoSyncColumns(db);
    await _restoreLegacyDataIfNeeded(db, 'diamond_story_v1.db');
  }

  Future<void> _ensureProcessCostColumns(Database db) async {
    final processTypeColumns = await db.rawQuery('PRAGMA table_info(process_types)');
    final hasTypeCost = processTypeColumns.any((c) => c['name'] == 'cost');
    if (!hasTypeCost) {
      await db.execute("ALTER TABLE process_types ADD COLUMN cost REAL DEFAULT 0");
    }

    final processColumns = await db.rawQuery('PRAGMA table_info(processes)');
    final hasFee = processColumns.any((c) => c['name'] == 'fee');
    if (!hasFee) {
      await db.execute("ALTER TABLE processes ADD COLUMN fee REAL DEFAULT 0");
    }
  }

  Future<void> _ensurePurchaseAutoSyncColumns(Database db) async {
    final purchaseColumns = await db.rawQuery('PRAGMA table_info(purchases)');
    final hasAutoGenerated = purchaseColumns.any((c) => c['name'] == 'auto_generated');
    if (!hasAutoGenerated) {
      await db.execute('ALTER TABLE purchases ADD COLUMN auto_generated INTEGER DEFAULT 0');
    }

    final hasAutoSource = purchaseColumns.any((c) => c['name'] == 'auto_source');
    if (!hasAutoSource) {
      await db.execute('ALTER TABLE purchases ADD COLUMN auto_source TEXT');
    }

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_purchases_auto_rough_by_lot
      ON purchases(lot_id)
      WHERE auto_generated = 1 AND auto_source = 'rough_stone'
    ''');
  }

  Future<void> _restoreLegacyDataIfNeeded(Database currentDb, String fileName) async {
    if (kIsWeb) return;

    final legacyPath = join(await getDatabasesPath(), fileName);
    if (legacyPath == currentDb.path) return;
    if (!await databaseExists(legacyPath)) return;

    final currentHasData = await _hasCoreData(currentDb);
    if (currentHasData) return;

    final legacyDb = await openDatabase(legacyPath, readOnly: true);
    try {
      final legacyHasData = await _hasCoreData(legacyDb);
      if (!legacyHasData) return;
      await _copyLegacyData(legacyDb, currentDb);
    } finally {
      await legacyDb.close();
    }
  }

  Future<bool> _hasCoreData(Database db) async {
    for (final table in [
      'rough_stones',
      'diamonds',
      'processes',
      'parties',
      'purchases',
      'sales',
      'payments',
    ]) {
      if (!await _tableExists(db, table)) continue;
      final result = await db.rawQuery('SELECT COUNT(*) AS cnt FROM $table');
      final count = (result.first['cnt'] as num?)?.toInt() ?? 0;
      if (count > 0) return true;
    }
    return false;
  }

  Future<bool> _tableExists(DatabaseExecutor db, String table) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [table],
    );
    return result.isNotEmpty;
  }

  Future<void> _copyLegacyData(Database fromDb, Database toDb) async {
    final orderedTables = [
      'app_settings',
      'expense_categories',
      'parties',
      'rough_stones',
      'diamonds',
      'process_types',
      'processes',
      'purchases',
      'sales',
      'payments',
    ];

    await toDb.transaction((txn) async {
      // Clear any seed/default rows first.
      for (final table in orderedTables.reversed) {
        if (await _tableExists(txn, table)) {
          await txn.delete(table);
        }
      }

      for (final table in orderedTables) {
        if (!await _tableExists(fromDb, table) || !await _tableExists(txn, table)) {
          continue;
        }

        final rows = await fromDb.query(table);
        for (final row in rows) {
          final record = Map<String, Object?>.from(row);
          if (table == 'process_types' && !record.containsKey('cost')) {
            record['cost'] = 0.0;
          }
          if (table == 'processes' && !record.containsKey('fee')) {
            record['fee'] = 0.0;
          }
          if (table == 'purchases' && !record.containsKey('auto_generated')) {
            record['auto_generated'] = 0;
          }
          if (table == 'purchases' && !record.containsKey('auto_source')) {
            record['auto_source'] = null;
          }
          await txn.insert(table, record, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import 'encryption_service.dart';

/// Platform-agnostic backup/restore service.
/// Works entirely with in-memory bytes — callers handle actual file I/O.
class BackupService {
  static const String backupExtension = '.dbackup';

  static const List<String> _tableNames = [
    'rough_stones', 'diamonds', 'process_types', 'processes',
    'parties', 'purchases', 'sales', 'payments', 'expense_categories',
  ];

  static const List<String> _csvImportOrder = [
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

  static const Map<String, String> _uniqueKeyByTable = {
    'rough_stones': 'lot_no',
    'diamonds': 'diamond_code',
    'process_types': 'name',
  };

  // ---------------------------------------------------------------------------
  // CREATE BACKUP  ->  returns encrypted bytes
  // ---------------------------------------------------------------------------

  /// Exports all tables, zips them, encrypts with [password].
  /// Returns the raw bytes of the .dbackup file.
  static Future<Uint8List> createBackupBytes(String password) async {
    final db = await DatabaseHelper.instance.database;
    final archive = Archive();

    for (final table in _tableNames) {
      final rows = await db.query(table);
      if (rows.isEmpty) {
        archive.addFile(ArchiveFile('$table.csv', 0, <int>[]));
        continue;
      }
      final headers = rows.first.keys.toList();
      final csvData = [
        headers,
        ...rows.map((row) => headers.map((h) => row[h]?.toString() ?? '').toList()),
      ];
      final csvString = const ListToCsvConverter().convert(csvData);
      final bytes = utf8.encode(csvString);
      archive.addFile(ArchiveFile('$table.csv', bytes.length, bytes));
    }

    final meta = jsonEncode({
      'app_version': '1.0.0',
      'backup_date': DateTime.now().toIso8601String(),
      'tables': _tableNames,
    });
    final metaBytes = utf8.encode(meta);
    archive.addFile(ArchiveFile('metadata.json', metaBytes.length, metaBytes));

    final zipBytes = ZipEncoder().encode(archive)!;
    final encrypted = EncryptionService.encryptBytes(
        Uint8List.fromList(zipBytes), password);

    // Update last_backup timestamp
    await db.execute(
      "UPDATE app_settings SET last_backup = ? WHERE id = 1",
      [DateTime.now().toIso8601String()],
    );

    return Uint8List.fromList(utf8.encode(encrypted));
  }

  // ---------------------------------------------------------------------------
  // RESTORE BACKUP  <-  accepts encrypted bytes
  // ---------------------------------------------------------------------------

  /// Decrypts and restores all tables from [backupBytes].
  static Future<void> restoreBackupBytes(
      Uint8List backupBytes, String password) async {
    final encryptedString = utf8.decode(backupBytes);
    final zipBytes = EncryptionService.decryptBytes(encryptedString, password);
    final archive = ZipDecoder().decodeBytes(zipBytes);

    final db = await DatabaseHelper.instance.database;

    for (final table in _tableNames) {
      final entry = archive.findFile('$table.csv');
      if (entry == null || !entry.isFile) continue;

      final csvString = utf8.decode(entry.content as List<int>);
      final rows = const CsvToListConverter().convert(csvString);
      if (rows.isEmpty || rows.length < 2) continue;

      final headers = rows.first.map((e) => e.toString()).toList();
      await db.delete(table);
      final batch = db.batch();
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final map = <String, dynamic>{};
        for (var j = 0; j < headers.length; j++) {
          map[headers[j]] = j < row.length ? row[j] : null;
        }
        batch.insert(table, map);
      }
      await batch.commit(noResult: true);
    }
  }

  // ---------------------------------------------------------------------------
  // METADATA
  // ---------------------------------------------------------------------------

  /// Get the last backup timestamp from settings.
  static Future<String?> getLastBackupTime() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('app_settings', limit: 1);
    if (result.isEmpty) return null;
    return result.first['last_backup'] as String?;
  }

  /// Generates a timestamped filename for a backup file.
  static String generateFileName() {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    return 'diamond_backup_$timestamp$backupExtension';
  }

  /// Generates a timestamped filename for a CSV export ZIP.
  static String generateExportFileName() {
    final timestamp = DateTime.now()
        .toIso8601String()
        .substring(0, 19)
        .replaceAll(':', '-');
    return 'diamond_export_$timestamp.zip';
  }

  // ---------------------------------------------------------------------------
  // CSV EXPORT  ->  returns ZIP bytes (no encryption)
  // ---------------------------------------------------------------------------

  /// Exports all tables as CSV files bundled in a ZIP archive.
  /// The ZIP is unencrypted and can be opened in Excel / Google Sheets.
  static Future<Uint8List> exportToCsvZip() async {
    final db = await DatabaseHelper.instance.database;
    final archive = Archive();

    for (final table in _tableNames) {
      final rows = await db.query(table);
      final List<List<dynamic>> csvData;
      if (rows.isEmpty) {
        csvData = [[]];
      } else {
        final headers = rows.first.keys.toList();
        csvData = [
          headers,
          ...rows.map(
              (row) => headers.map((h) => row[h]?.toString() ?? '').toList()),
        ];
      }
      final csvString = const ListToCsvConverter().convert(csvData);
      final bytes = utf8.encode(csvString);
      archive.addFile(ArchiveFile('$table.csv', bytes.length, bytes));
    }

    final zipBytes = ZipEncoder().encode(archive)!;
    return Uint8List.fromList(zipBytes);
  }

  // ---------------------------------------------------------------------------
  // RESTORE CSV ZIP  <-  accepts unencrypted ZIP bytes
  // ---------------------------------------------------------------------------

  /// Restores data from a CSV ZIP created by [exportToCsvZip].
  ///
  /// When [merge] is true, existing data is kept and incoming rows overwrite
  /// conflicts when keys match. When false, existing rows in backup tables are
  /// cleared first.
  static Future<CsvRestoreResult> restoreFromCsvZipBytes(
    Uint8List zipBytes, {
    bool merge = true,
  }) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final db = await DatabaseHelper.instance.database;
    final result = CsvRestoreResult();

    final tableColumns = <String, Map<String, String>>{};
    for (final table in _csvImportOrder) {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      tableColumns[table] = {
        for (final col in info)
          (col['name'] as String): ((col['type'] as String?) ?? ''),
      };
    }

    await db.transaction((txn) async {
      if (!merge) {
        for (final table in _csvImportOrder.reversed) {
          await txn.delete(table);
        }
      }

      for (final table in _csvImportOrder) {
        final entry = archive.findFile('$table.csv');
        if (entry == null || !entry.isFile) continue;

        final csvString = utf8.decode(entry.content as List<int>);
        final rawRows = const CsvToListConverter().convert(csvString);
        if (rawRows.isEmpty) continue;

        final headers = rawRows.first
            .map((e) => _normalizeHeader(e?.toString() ?? ''))
            .where((h) => h.isNotEmpty)
            .toList();
        if (headers.isEmpty || rawRows.length < 2) continue;

        final validColumns = tableColumns[table]!;
        final filteredHeaders = headers.where(validColumns.containsKey).toList();
        if (filteredHeaders.isEmpty) continue;

        final stats = result._stats.putIfAbsent(table, TableImportStats.new);
        final uniqueKey = _uniqueKeyByTable[table];

        for (var i = 1; i < rawRows.length; i++) {
          final row = rawRows[i];
          try {
            final values = row.cast<Object?>();
            final record = <String, dynamic>{};

            for (var j = 0; j < headers.length; j++) {
              if (j >= values.length) continue;
              final column = headers[j];
              if (!validColumns.containsKey(column)) continue;
              record[column] = _coerceValue(values[j], validColumns[column]!);
            }

            if (record.isEmpty) {
              stats.skipped++;
              continue;
            }

            if (!merge) {
              await txn.insert(
                table,
                record,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              stats.inserted++;
              continue;
            }

            final overwriteDone = await _mergeUpsertRow(
              txn: txn,
              table: table,
              record: record,
              uniqueKey: uniqueKey,
            );

            if (overwriteDone) {
              stats.overwritten++;
            } else {
              stats.inserted++;
            }
          } catch (_) {
            stats.skipped++;
          }
        }
      }
    });

    return result;
  }

  static Future<bool> _mergeUpsertRow({
    required Transaction txn,
    required String table,
    required Map<String, dynamic> record,
    required String? uniqueKey,
  }) async {
    final id = record['id'];
    if (id != null) {
      final updateMap = Map<String, dynamic>.from(record)..remove('id');
      final updated = await txn.update(
        table,
        updateMap,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (updated > 0) return true;
      await txn.insert(table, record, conflictAlgorithm: ConflictAlgorithm.replace);
      return false;
    }

    if (uniqueKey != null && record.containsKey(uniqueKey) && record[uniqueKey] != null) {
      final match = await txn.query(
        table,
        columns: const ['id'],
        where: '$uniqueKey = ?',
        whereArgs: [record[uniqueKey]],
        limit: 1,
      );
      if (match.isNotEmpty) {
        final matchedId = match.first['id'];
        final updateMap = Map<String, dynamic>.from(record)..remove('id');
        await txn.update(
          table,
          updateMap,
          where: 'id = ?',
          whereArgs: [matchedId],
        );
        return true;
      }
    }

    await txn.insert(table, record, conflictAlgorithm: ConflictAlgorithm.replace);
    return false;
  }

  static String _normalizeHeader(String value) {
    return value.replaceFirst('\ufeff', '').trim();
  }

  static dynamic _coerceValue(Object? value, String sqliteType) {
    if (value == null) return null;

    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    final upper = sqliteType.toUpperCase();
    if (upper.contains('INT')) {
      final n = num.tryParse(raw);
      return n?.toInt();
    }
    if (upper.contains('REAL') || upper.contains('FLOA') || upper.contains('DOUB')) {
      return num.tryParse(raw)?.toDouble();
    }
    return raw;
  }
}

class CsvRestoreResult {
  final Map<String, TableImportStats> _stats = {};

  Map<String, TableImportStats> get stats => Map.unmodifiable(_stats);

  int get inserted => _stats.values.fold(0, (sum, s) => sum + s.inserted);

  int get overwritten => _stats.values.fold(0, (sum, s) => sum + s.overwritten);

  int get skipped => _stats.values.fold(0, (sum, s) => sum + s.skipped);
}

class TableImportStats {
  int inserted = 0;
  int overwritten = 0;
  int skipped = 0;
}

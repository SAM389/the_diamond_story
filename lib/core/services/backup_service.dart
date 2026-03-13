import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
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
}

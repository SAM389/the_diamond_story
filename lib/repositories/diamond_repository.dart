import '../core/database/database_helper.dart';
import '../models/diamond.dart';

class DiamondRepository {
  final _db = DatabaseHelper.instance;

  Future<void> reconcileSaleStatuses() async {
    final db = await _db.database;

    // Keep compatibility with databases that may not have sale_items yet.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        diamond_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    final salesColumns = await db.rawQuery('PRAGMA table_info(sales)');
    final hasDeletedAt = salesColumns.any((c) => c['name'] == 'deleted_at');
    if (!hasDeletedAt) {
      await db.execute('ALTER TABLE sales ADD COLUMN deleted_at TEXT');
    }

    // Any diamond referenced by either new or legacy sales storage should be sold.
    await db.execute('''
      UPDATE diamonds
      SET status = 'sold'
      WHERE id IN (
        SELECT si.diamond_id
        FROM sale_items si
        INNER JOIN sales s ON s.id = si.sale_id
        WHERE s.deleted_at IS NULL
        UNION
        SELECT diamond_id FROM sales WHERE diamond_id IS NOT NULL AND deleted_at IS NULL
      )
    ''');

    // Release sold status for diamonds no longer referenced by any sale.
    await db.execute('''
      UPDATE diamonds
      SET status = 'completed'
      WHERE status = 'sold'
        AND id NOT IN (
          SELECT si.diamond_id
          FROM sale_items si
          INNER JOIN sales s ON s.id = si.sale_id
          WHERE s.deleted_at IS NULL
          UNION
          SELECT diamond_id FROM sales WHERE diamond_id IS NOT NULL AND deleted_at IS NULL
        )
    ''');
  }

  Future<List<Diamond>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('diamonds', orderBy: 'created_at DESC');
    return maps.map(Diamond.fromMap).toList();
  }

  Future<List<Diamond>> getByParentLot(String lotNo) async {
    final db = await _db.database;
    final maps = await db.query('diamonds', where: 'parent_lot = ?', whereArgs: [lotNo]);
    return maps.map(Diamond.fromMap).toList();
  }

  Future<Diamond?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query('diamonds', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Diamond.fromMap(maps.first);
  }

  Future<Diamond?> getByCode(String code) async {
    final db = await _db.database;
    final maps = await db.query('diamonds', where: 'diamond_code = ?', whereArgs: [code]);
    if (maps.isEmpty) return null;
    return Diamond.fromMap(maps.first);
  }

  Future<int> insert(Diamond diamond) async {
    final db = await _db.database;
    return db.insert('diamonds', diamond.toMap());
  }

  Future<void> insertAll(List<Diamond> diamonds) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final d in diamonds) {
      batch.insert('diamonds', d.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<int> update(Diamond diamond) async {
    final db = await _db.database;
    return db.update('diamonds', diamond.toMap(), where: 'id = ?', whereArgs: [diamond.id]);
  }

  Future<int> updateStatus(int id, String status) async {
    final db = await _db.database;
    return db.update('diamonds', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete('diamonds', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM diamonds');
    return result.first['cnt'] as int;
  }

  Future<double> totalWeight() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT SUM(weight) as total FROM diamonds');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> countByStatus(String status) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM diamonds WHERE status = ?',
      [status],
    );
    return result.first['cnt'] as int;
  }

  /// Split a rough lot into multiple diamonds using explicit per-item weights.
  Future<void> splitLot(String lotNo, List<String> codes, List<double> weights) async {
    if (codes.length != weights.length) {
      throw ArgumentError('Codes and weights length must be the same.');
    }

    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    for (var i = 0; i < codes.length; i++) {
      batch.insert('diamonds', {
        'parent_lot': lotNo,
        'diamond_code': codes[i],
        'weight': weights[i],
        'status': 'raw',
        'created_at': now,
      });
    }
    await batch.commit(noResult: true);
  }
}

import '../core/database/database_helper.dart';
import '../models/diamond.dart';

class DiamondRepository {
  final _db = DatabaseHelper.instance;

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

  /// Split a rough lot into multiple diamonds
  Future<void> splitLot(String lotNo, List<String> codes, double totalWeight) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    final weightEach = codes.isEmpty ? 0.0 : totalWeight / codes.length;
    final batch = db.batch();
    for (final code in codes) {
      batch.insert('diamonds', {
        'parent_lot': lotNo,
        'diamond_code': code,
        'weight': weightEach,
        'status': 'raw',
        'created_at': now,
      });
    }
    await batch.commit(noResult: true);
  }
}

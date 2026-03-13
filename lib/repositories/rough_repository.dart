import '../core/database/database_helper.dart';
import '../models/rough_stone.dart';

class RoughRepository {
  final _db = DatabaseHelper.instance;

  Future<List<RoughStone>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('rough_stones', orderBy: 'created_at DESC');
    return maps.map(RoughStone.fromMap).toList();
  }

  Future<RoughStone?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query('rough_stones', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return RoughStone.fromMap(maps.first);
  }

  Future<RoughStone?> getByLotNo(String lotNo) async {
    final db = await _db.database;
    final maps = await db.query('rough_stones', where: 'lot_no = ?', whereArgs: [lotNo]);
    if (maps.isEmpty) return null;
    return RoughStone.fromMap(maps.first);
  }

  Future<int> insert(RoughStone stone) async {
    final db = await _db.database;
    return db.insert('rough_stones', stone.toMap());
  }

  Future<int> update(RoughStone stone) async {
    final db = await _db.database;
    return db.update(
      'rough_stones',
      stone.toMap(),
      where: 'id = ?',
      whereArgs: [stone.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete('rough_stones', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM rough_stones');
    return result.first['cnt'] as int;
  }

  Future<double> totalWeight() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT SUM(weight) as total FROM rough_stones');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Auto-generate the next lot number
  Future<String> nextLotNo() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM rough_stones');
    final cnt = (result.first['cnt'] as int?) ?? 0;
    return 'LOT-${(cnt + 1).toString().padLeft(3, '0')}';
  }
}

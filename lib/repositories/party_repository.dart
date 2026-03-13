import '../core/database/database_helper.dart';
import '../models/party.dart';

class PartyRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Party>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('parties', orderBy: 'name ASC');
    return maps.map(Party.fromMap).toList();
  }

  Future<List<Party>> getByType(String type) async {
    final db = await _db.database;
    final maps = await db.query('parties', where: 'type = ?', whereArgs: [type], orderBy: 'name ASC');
    return maps.map(Party.fromMap).toList();
  }

  Future<Party?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query('parties', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Party.fromMap(maps.first);
  }

  Future<int> insert(Party party) async {
    final db = await _db.database;
    return db.insert('parties', party.toMap());
  }

  Future<int> update(Party party) async {
    final db = await _db.database;
    return db.update('parties', party.toMap(), where: 'id = ?', whereArgs: [party.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete('parties', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM parties');
    return result.first['cnt'] as int;
  }
}

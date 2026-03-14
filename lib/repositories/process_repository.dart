import '../core/database/database_helper.dart';
import '../models/process.dart';
import '../models/process_type.dart';

class ProcessRepository {
  final _db = DatabaseHelper.instance;

  Future<List<ProcessType>> getAllTypes() async {
    final db = await _db.database;
    final maps = await db.query('process_types', orderBy: 'name ASC');
    return maps.map(ProcessType.fromMap).toList();
  }

  Future<int> insertType(ProcessType type) async {
    final db = await _db.database;
    return db.insert('process_types', type.toMap());
  }

  Future<int> deleteType(int id) async {
    final db = await _db.database;
    return db.delete('process_types', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Process>> getAll() async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT p.*, d.diamond_code, pt.name as process_type_name, pt.cost as process_type_cost
      FROM processes p
      LEFT JOIN diamonds d ON d.id = p.diamond_id
      LEFT JOIN process_types pt ON pt.id = p.process_type_id
      ORDER BY p.created_at DESC
    ''');
    return maps.map(Process.fromMap).toList();
  }

  Future<List<Process>> getByDiamond(int diamondId) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT p.*, d.diamond_code, pt.name as process_type_name, pt.cost as process_type_cost
      FROM processes p
      LEFT JOIN diamonds d ON d.id = p.diamond_id
      LEFT JOIN process_types pt ON pt.id = p.process_type_id
      WHERE p.diamond_id = ?
      ORDER BY p.created_at DESC
    ''', [diamondId]);
    return maps.map(Process.fromMap).toList();
  }

  Future<Process?> getActiveProcess(int diamondId) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT p.*, d.diamond_code, pt.name as process_type_name, pt.cost as process_type_cost
      FROM processes p
      LEFT JOIN diamonds d ON d.id = p.diamond_id
      LEFT JOIN process_types pt ON pt.id = p.process_type_id
      WHERE p.diamond_id = ? AND p.status = 'pending'
      LIMIT 1
    ''', [diamondId]);
    if (maps.isEmpty) return null;
    return Process.fromMap(maps.first);
  }

  Future<int> insert(Process process) async {
    final db = await _db.database;
    // A diamond can have multiple process steps (e.g., cutting, grading, polishing).
    final id = await db.insert('processes', process.toMap());
    // Update diamond status
    await db.update(
      'diamonds',
      {'status': 'in_process'},
      where: 'id = ?',
      whereArgs: [process.diamondId],
    );
    return id;
  }

  Future<int> update(Process process) async {
    final db = await _db.database;
    if (process.id == null) throw Exception('Process id is required for update');

    final existingRows = await db.query(
      'processes',
      where: 'id = ?',
      whereArgs: [process.id],
      limit: 1,
    );
    if (existingRows.isEmpty) throw Exception('Process not found');

    final existing = Process.fromMap(existingRows.first);

    await db.update(
      'processes',
      process.toMap(),
      where: 'id = ?',
      whereArgs: [process.id],
    );

    if (process.status == 'pending') {
      await db.update(
        'diamonds',
        {'status': 'in_process'},
        where: 'id = ?',
        whereArgs: [process.diamondId],
      );
    }

    await _refreshDiamondStatus(existing.diamondId);
    if (existing.diamondId != process.diamondId) {
      await _refreshDiamondStatus(process.diamondId);
    }

    return process.id!;
  }

  Future<int> complete(int processId, String toDate) async {
    final db = await _db.database;
    // Get process to find diamond id
    final maps = await db.query('processes', where: 'id = ?', whereArgs: [processId]);
    if (maps.isEmpty) throw Exception('Process not found');
    final process = Process.fromMap(maps.first);

    await db.update(
      'processes',
      {'status': 'completed', 'to_date': toDate},
      where: 'id = ?',
      whereArgs: [processId],
    );

    // Check if any more pending processes remain for this diamond
    final pending = await db.query(
      'processes',
      where: 'diamond_id = ? AND status = ?',
      whereArgs: [process.diamondId, 'pending'],
    );
    if (pending.isEmpty) {
      await db.update(
        'diamonds',
        {'status': 'completed'},
        where: 'id = ?',
        whereArgs: [process.diamondId],
      );
    }
    return processId;
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    final existingRows = await db.query(
      'processes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    final deleted = await db.delete('processes', where: 'id = ?', whereArgs: [id]);
    if (existingRows.isNotEmpty) {
      final process = Process.fromMap(existingRows.first);
      await _refreshDiamondStatus(process.diamondId);
    }
    return deleted;
  }

  Future<int> countPending() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM processes WHERE status = 'pending'",
    );
    return result.first['cnt'] as int;
  }

  Future<int> countCompleted() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT COUNT(DISTINCT diamond_id) as cnt FROM processes WHERE status = 'completed'",
    );
    return result.first['cnt'] as int;
  }

  /// Returns [{name: String, count: int}] for pending processes grouped by process type.
  Future<List<Map<String, dynamic>>> countByType() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT pt.name, COUNT(*) as cnt
      FROM processes p
      JOIN process_types pt ON pt.id = p.process_type_id
      WHERE p.status = 'pending'
      GROUP BY pt.id, pt.name
      ORDER BY cnt DESC
    ''');
    return rows
        .map((r) => {'name': r['name'] as String, 'count': (r['cnt'] as int)})
        .toList();
  }

  Future<List<Process>> getRecent(int limit) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT p.*, d.diamond_code, pt.name as process_type_name, pt.cost as process_type_cost
      FROM processes p
      LEFT JOIN diamonds d ON d.id = p.diamond_id
      LEFT JOIN process_types pt ON pt.id = p.process_type_id
      ORDER BY p.created_at DESC
      LIMIT ?
    ''', [limit]);
    return maps.map(Process.fromMap).toList();
  }

  Future<List<Process>> getOverdue() async {
    final db = await _db.database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final maps = await db.rawQuery('''
      SELECT p.*, d.diamond_code, pt.name as process_type_name, pt.cost as process_type_cost
      FROM processes p
      LEFT JOIN diamonds d ON d.id = p.diamond_id
      LEFT JOIN process_types pt ON pt.id = p.process_type_id
      WHERE p.status = 'pending' AND p.to_date IS NOT NULL AND p.to_date < ?
      ORDER BY p.to_date ASC
    ''', [todayStr]);
    return maps.map(Process.fromMap).toList();
  }

  Future<void> _refreshDiamondStatus(int diamondId) async {
    final db = await _db.database;
    final pending = await db.query(
      'processes',
      where: 'diamond_id = ? AND status = ?',
      whereArgs: [diamondId, 'pending'],
      limit: 1,
    );
    if (pending.isNotEmpty) {
      await db.update(
        'diamonds',
        {'status': 'in_process'},
        where: 'id = ?',
        whereArgs: [diamondId],
      );
      return;
    }

    final allForDiamond = await db.query(
      'processes',
      where: 'diamond_id = ?',
      whereArgs: [diamondId],
      limit: 1,
    );
    await db.update(
      'diamonds',
      {'status': allForDiamond.isEmpty ? 'raw' : 'completed'},
      where: 'id = ?',
      whereArgs: [diamondId],
    );
  }
}

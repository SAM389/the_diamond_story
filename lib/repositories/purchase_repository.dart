import '../core/database/database_helper.dart';
import '../models/purchase.dart';

class PurchaseRepository {
  final _db = DatabaseHelper.instance;
  static const String roughStoneAutoSource = 'rough_stone';

  Future<List<Purchase>> getAll() async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT p.*, pa.name as party_name, rs.lot_no
      FROM purchases p
      LEFT JOIN parties pa ON pa.id = p.party_id
      LEFT JOIN rough_stones rs ON rs.id = p.lot_id
      WHERE p.auto_generated = 1 AND p.auto_source = ?
      ORDER BY p.created_at DESC
    ''', [roughStoneAutoSource]);
    return maps.map(Purchase.fromMap).toList();
  }

  Future<List<Purchase>> getAllRaw() async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT p.*, pa.name as party_name, rs.lot_no
      FROM purchases p
      LEFT JOIN parties pa ON pa.id = p.party_id
      LEFT JOIN rough_stones rs ON rs.id = p.lot_id
      ORDER BY p.created_at DESC
    ''');
    return maps.map(Purchase.fromMap).toList();
  }

  Future<int> insert(Purchase purchase) async {
    throw UnsupportedError(
      'Manual purchase creation is disabled. Purchases are auto-managed from rough stones.',
    );
  }

  Future<int> upsertAutoForRoughStone({
    required int lotId,
    required int partyId,
    required double amount,
    required String date,
    String? notes,
  }) async {
    final db = await _db.database;
    final existing = await db.query(
      'purchases',
      columns: ['id'],
      where: 'lot_id = ? AND auto_generated = 1 AND auto_source = ?',
      whereArgs: [lotId, roughStoneAutoSource],
      limit: 1,
    );

    final payload = <String, dynamic>{
      'party_id': partyId,
      'lot_id': lotId,
      'amount': amount,
      'date': date,
      'auto_generated': 1,
      'auto_source': roughStoneAutoSource,
      'notes': notes,
    };

    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      return db.update('purchases', payload, where: 'id = ?', whereArgs: [id]);
    }

    payload['created_at'] = DateTime.now().toIso8601String();
    return db.insert('purchases', payload);
  }

  Future<int> update(Purchase purchase) async {
    final db = await _db.database;
    return db.update('purchases', purchase.toMap(), where: 'id = ?', whereArgs: [purchase.id]);
  }

  Future<int> delete(int id) async {
    throw UnsupportedError(
      'Manual purchase deletion is disabled. Delete the related rough stone instead.',
    );
  }

  Future<int> deleteAutoForRoughStoneByLotId(int lotId) async {
    final db = await _db.database;
    return db.delete(
      'purchases',
      where: 'lot_id = ? AND auto_generated = 1 AND auto_source = ?',
      whereArgs: [lotId, roughStoneAutoSource],
    );
  }

  Future<double> totalAmount() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM purchases');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}

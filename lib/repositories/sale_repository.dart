import '../core/database/database_helper.dart';
import '../models/sale.dart';

class SaleRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Sale>> getAll() async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT s.*, pa.name as party_name, d.diamond_code
      FROM sales s
      LEFT JOIN parties pa ON pa.id = s.party_id
      LEFT JOIN diamonds d ON d.id = s.diamond_id
      ORDER BY s.created_at DESC
    ''');
    return maps.map(Sale.fromMap).toList();
  }

  Future<int> insert(Sale sale) async {
    final db = await _db.database;
    final id = await db.insert('sales', sale.toMap());
    // Mark diamond as sold
    if (sale.diamondId != null) {
      await db.update(
        'diamonds',
        {'status': 'sold'},
        where: 'id = ?',
        whereArgs: [sale.diamondId],
      );
    }
    return id;
  }

  Future<int> update(Sale sale) async {
    final db = await _db.database;
    return db.update('sales', sale.toMap(), where: 'id = ?', whereArgs: [sale.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.transaction<int>((txn) async {
      final rows = await txn.query(
        'sales',
        columns: ['diamond_id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      int? diamondId;
      if (rows.isNotEmpty) {
        final rawDiamondId = rows.first['diamond_id'];
        if (rawDiamondId is num) {
          diamondId = rawDiamondId.toInt();
        } else if (rawDiamondId is String) {
          diamondId = int.tryParse(rawDiamondId);
        }
      }

      final deletedCount = await txn.delete('sales', where: 'id = ?', whereArgs: [id]);

      if (deletedCount > 0 && diamondId != null) {
        final stillReferenced = await txn.rawQuery(
          'SELECT COUNT(*) as cnt FROM sales WHERE diamond_id = ?',
          [diamondId],
        );
        final rawCnt = stillReferenced.first['cnt'];
        final cnt = rawCnt is num
            ? rawCnt.toInt()
            : int.tryParse(rawCnt?.toString() ?? '0') ?? 0;
        if (cnt == 0) {
          await txn.update(
            'diamonds',
            {'status': 'completed'},
            where: 'id = ?',
            whereArgs: [diamondId],
          );
        }
      }

      return deletedCount;
    });
  }

  Future<double> totalRevenue() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT SUM(price) as total FROM sales');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> countSales() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM sales');
    return result.first['cnt'] as int;
  }
}

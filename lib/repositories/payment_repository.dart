import '../core/database/database_helper.dart';
import '../models/payment.dart';
import '../models/expense_category.dart';

class PaymentRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Payment>> getAll() async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT p.*, pa.name as party_name
      FROM payments p
      LEFT JOIN parties pa ON pa.id = p.party_id
      ORDER BY p.date DESC
    ''');
    return maps.map(Payment.fromMap).toList();
  }

  Future<int> insert(Payment payment) async {
    final db = await _db.database;
    return db.insert('payments', payment.toMap());
  }

  Future<int> update(Payment payment) async {
    final db = await _db.database;
    return db.update('payments', payment.toMap(), where: 'id = ?', whereArgs: [payment.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ExpenseCategory>> getAllCategories() async {
    final db = await _db.database;
    final maps = await db.query('expense_categories', orderBy: 'name ASC');
    return maps.map(ExpenseCategory.fromMap).toList();
  }

  Future<int> insertCategory(ExpenseCategory cat) async {
    final db = await _db.database;
    return db.insert('expense_categories', cat.toMap());
  }

  Future<int> deleteCategory(int id) async {
    final db = await _db.database;
    return db.delete('expense_categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> totals() async {
    final db = await _db.database;
    final paid = await db.rawQuery("SELECT SUM(amount) as t FROM payments WHERE type='paid'");
    final received = await db.rawQuery("SELECT SUM(amount) as t FROM payments WHERE type='received'");
    return {
      'paid': (paid.first['t'] as num?)?.toDouble() ?? 0.0,
      'received': (received.first['t'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<List<Payment>> getPending() async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT p.*, pa.name as party_name
      FROM payments p
      LEFT JOIN parties pa ON pa.id = p.party_id
      WHERE p.status = 'pending'
      ORDER BY p.date DESC
    ''');
    return maps.map(Payment.fromMap).toList();
  }

  Future<List<Payment>> getRecentCompleted(int limit) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT p.*, pa.name as party_name
      FROM payments p
      LEFT JOIN parties pa ON pa.id = p.party_id
      WHERE p.status = 'completed'
      ORDER BY p.date DESC
      LIMIT ?
    ''', [limit]);
    return maps.map(Payment.fromMap).toList();
  }

  Future<double> pendingTotal() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT SUM(amount) as t FROM payments WHERE status = 'pending'",
    );
    return (result.first['t'] as num?)?.toDouble() ?? 0.0;
  }
}

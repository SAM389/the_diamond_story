import '../core/database/database_helper.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';

class SaleRepository {
  final _db = DatabaseHelper.instance;

  Future<void> _ensureSalesSoftDelete(dynamic db) async {
    final salesColumns = await db.rawQuery('PRAGMA table_info(sales)');
    final hasDeletedAt =
        salesColumns.any((column) => column['name'] == 'deleted_at');
    if (!hasDeletedAt) {
      await db.execute('ALTER TABLE sales ADD COLUMN deleted_at TEXT');
    }
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sales_deleted_at ON sales(deleted_at)',
    );
  }

  Future<void> _ensureSalesBillNo(dynamic db) async {
    final salesColumns = await db.rawQuery('PRAGMA table_info(sales)');
    final hasBillNo =
        salesColumns.any((column) => column['name'] == 'bill_no');
    if (!hasBillNo) {
      await db.execute('ALTER TABLE sales ADD COLUMN bill_no TEXT');
    }
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_sales_bill_no ON sales(bill_no)',
    );
  }

  Future<String> _nextBillNo(dynamic txnOrDb) async {
    final result = await txnOrDb.rawQuery('''
      SELECT MAX(CAST(SUBSTR(bill_no, 6) AS INTEGER)) AS seq
      FROM sales
      WHERE bill_no LIKE 'BILL-%'
    ''');
    final currentMax = (result.first['seq'] as num?)?.toInt() ?? 0;
    final next = currentMax + 1;
    return 'BILL-${next.toString().padLeft(6, '0')}';
  }

  Future<void> _ensureSaleItemsSchema(dynamic db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        diamond_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON sale_items(sale_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sale_items_diamond_id ON sale_items(diamond_id)',
    );

    final saleColumns = await db.rawQuery('PRAGMA table_info(sales)');
    final hasLegacyDiamondId =
        saleColumns.any((column) => column['name'] == 'diamond_id');
    if (!hasLegacyDiamondId) return;

    // Backfill old one-diamond sales into sale_items if still missing.
    await db.execute('''
      INSERT INTO sale_items (sale_id, diamond_id, amount, created_at)
      SELECT s.id, s.diamond_id, COALESCE(s.price, 0), COALESCE(s.created_at, CURRENT_TIMESTAMP)
      FROM sales s
      WHERE s.diamond_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM sale_items si
          WHERE si.sale_id = s.id AND si.diamond_id = s.diamond_id
        )
    ''');
  }

  Future<int> _countDiamondReferences(dynamic txnOrDb, int diamondId) async {
    final saleItemRef = await txnOrDb.rawQuery(
      '''
      SELECT COUNT(*) as cnt
      FROM sale_items si
      INNER JOIN sales s ON s.id = si.sale_id
      WHERE si.diamond_id = ? AND s.deleted_at IS NULL
      ''',
      [diamondId],
    );
    final rawSaleItemCnt = saleItemRef.first['cnt'];
    final saleItemCnt = rawSaleItemCnt is num
        ? rawSaleItemCnt.toInt()
        : int.tryParse(rawSaleItemCnt?.toString() ?? '0') ?? 0;

    final salesRef = await txnOrDb.rawQuery(
      'SELECT COUNT(*) as cnt FROM sales WHERE diamond_id = ? AND deleted_at IS NULL',
      [diamondId],
    );
    final rawSalesCnt = salesRef.first['cnt'];
    final salesCnt = rawSalesCnt is num
        ? rawSalesCnt.toInt()
        : int.tryParse(rawSalesCnt?.toString() ?? '0') ?? 0;

    return saleItemCnt + salesCnt;
  }

  Future<List<Sale>> getAll() async {
    final db = await _db.database;
    await _ensureSaleItemsSchema(db);
    await _ensureSalesBillNo(db);
    await _ensureSalesSoftDelete(db);
    final maps = await db.rawQuery('''
      SELECT s.*, pa.name as party_name,
        COALESCE(GROUP_CONCAT(d.diamond_code, ', '), '-') as diamond_code
      FROM sales s
      LEFT JOIN parties pa ON pa.id = s.party_id
      LEFT JOIN sale_items si ON si.sale_id = s.id
      LEFT JOIN diamonds d ON d.id = si.diamond_id
      GROUP BY s.id
      ORDER BY s.created_at DESC
    ''');

    final sales = maps.map(Sale.fromMap).toList();
    if (sales.isEmpty) return sales;

    final saleIds = sales.where((s) => s.id != null).map((s) => s.id!).toList();
    final placeholders = List.filled(saleIds.length, '?').join(',');
    final itemRows = await db.rawQuery('''
      SELECT si.*, d.diamond_code, d.weight
      FROM sale_items si
      LEFT JOIN diamonds d ON d.id = si.diamond_id
      WHERE si.sale_id IN ($placeholders)
      ORDER BY si.sale_id ASC, si.id ASC
    ''', saleIds);

    final itemsBySale = <int, List<SaleItem>>{};
    for (final row in itemRows) {
      final item = SaleItem.fromMap(row);
      itemsBySale.putIfAbsent(item.saleId, () => <SaleItem>[]).add(item);
    }

    return sales
        .map((sale) => sale.copyWith(items: itemsBySale[sale.id] ?? const []))
        .toList();
  }

  Future<int> insert(Sale sale) async {
    final db = await _db.database;
    await _ensureSaleItemsSchema(db);
    await _ensureSalesBillNo(db);
    await _ensureSalesSoftDelete(db);
    if (sale.items.isEmpty) {
      throw StateError('Select at least one diamond.');
    }
    final ids = sale.items.map((e) => e.diamondId).toSet();
    if (ids.length != sale.items.length) {
      throw StateError('Same diamond cannot be selected multiple times.');
    }
    if (sale.items.any((e) => e.amount <= 0)) {
      throw StateError('Each selected diamond must have amount greater than 0.');
    }

    return db.transaction<int>((txn) async {
      final total = sale.items.fold<double>(0.0, (sum, i) => sum + i.amount);
      final billNo = await _nextBillNo(txn);
      final saleId = await txn.insert('sales', {
        'bill_no': billNo,
        'deleted_at': null,
        'party_id': sale.partyId,
        'price': total,
        'date': sale.date,
        'notes': sale.notes,
        'created_at': sale.createdAt,
      });

      final now = DateTime.now().toIso8601String();
      for (final item in sale.items) {
        await txn.insert('sale_items', {
          'sale_id': saleId,
          'diamond_id': item.diamondId,
          'amount': item.amount,
          'created_at': now,
        });
        await txn.update(
          'diamonds',
          {'status': 'sold'},
          where: 'id = ?',
          whereArgs: [item.diamondId],
        );
      }

      return saleId;
    });
  }

  Future<int> update(Sale sale) async {
    final db = await _db.database;
    await _ensureSaleItemsSchema(db);
    await _ensureSalesBillNo(db);
    await _ensureSalesSoftDelete(db);
    if (sale.id == null) {
      throw StateError('Sale id is required for update.');
    }
    if (sale.items.isEmpty) {
      throw StateError('Select at least one diamond.');
    }
    final ids = sale.items.map((e) => e.diamondId).toSet();
    if (ids.length != sale.items.length) {
      throw StateError('Same diamond cannot be selected multiple times.');
    }
    if (sale.items.any((e) => e.amount <= 0)) {
      throw StateError('Each selected diamond must have amount greater than 0.');
    }

    return db.transaction<int>((txn) async {
      final existingRows = await txn.query(
        'sale_items',
        columns: ['diamond_id'],
        where: 'sale_id = ?',
        whereArgs: [sale.id],
      );
      final existingIds = existingRows
          .map((r) => r['diamond_id'])
          .whereType<num>()
          .map((n) => n.toInt())
          .toSet();

      await txn.delete('sale_items', where: 'sale_id = ?', whereArgs: [sale.id]);

      final now = DateTime.now().toIso8601String();
      for (final item in sale.items) {
        await txn.insert('sale_items', {
          'sale_id': sale.id,
          'diamond_id': item.diamondId,
          'amount': item.amount,
          'created_at': now,
        });
        await txn.update(
          'diamonds',
          {'status': 'sold'},
          where: 'id = ?',
          whereArgs: [item.diamondId],
        );
      }

      final removedIds = existingIds.difference(ids);
      for (final diamondId in removedIds) {
        final cnt = await _countDiamondReferences(txn, diamondId);
        if (cnt == 0) {
          await txn.update(
            'diamonds',
            {'status': 'completed'},
            where: 'id = ?',
            whereArgs: [diamondId],
          );
        }
      }

      final total = sale.items.fold<double>(0.0, (sum, i) => sum + i.amount);
      return txn.update(
        'sales',
        {
          'party_id': sale.partyId,
          'price': total,
          'date': sale.date,
          'notes': sale.notes,
          'deleted_at': sale.deletedAt,
        },
        where: 'id = ?',
        whereArgs: [sale.id],
      );
    });
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    await _ensureSaleItemsSchema(db);
    await _ensureSalesBillNo(db);
    await _ensureSalesSoftDelete(db);
    return db.transaction<int>((txn) async {
      final legacySaleRows = await txn.query(
        'sales',
        columns: ['diamond_id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      final rows = await txn.query(
        'sale_items',
        columns: ['diamond_id'],
        where: 'sale_id = ?',
        whereArgs: [id],
      );
      final diamondIds = rows
          .map((r) => r['diamond_id'])
          .whereType<num>()
          .map((n) => n.toInt())
          .toSet()
          .toSet();

      if (legacySaleRows.isNotEmpty) {
        final legacyDiamondRaw = legacySaleRows.first['diamond_id'];
        if (legacyDiamondRaw is num) {
          diamondIds.add(legacyDiamondRaw.toInt());
        } else if (legacyDiamondRaw != null) {
          final parsed = int.tryParse(legacyDiamondRaw.toString());
          if (parsed != null) {
            diamondIds.add(parsed);
          }
        }
      }

      final deletedCount = await txn.update(
        'sales',
        {'deleted_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );

      if (deletedCount > 0) {
        for (final diamondId in diamondIds) {
          final cnt = await _countDiamondReferences(txn, diamondId);
          if (cnt == 0) {
            await txn.update(
              'diamonds',
              {'status': 'completed'},
              where: 'id = ?',
              whereArgs: [diamondId],
            );
          }
        }
      }

      return deletedCount;
    });
  }

  Future<int> restore(int id) async {
    final db = await _db.database;
    await _ensureSaleItemsSchema(db);
    await _ensureSalesBillNo(db);
    await _ensureSalesSoftDelete(db);
    return db.transaction<int>((txn) async {
      final legacySaleRows = await txn.query(
        'sales',
        columns: ['diamond_id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      final rows = await txn.query(
        'sale_items',
        columns: ['diamond_id'],
        where: 'sale_id = ?',
        whereArgs: [id],
      );
      final diamondIds = rows
          .map((r) => r['diamond_id'])
          .whereType<num>()
          .map((n) => n.toInt())
          .toSet();

      if (legacySaleRows.isNotEmpty) {
        final legacyDiamondRaw = legacySaleRows.first['diamond_id'];
        if (legacyDiamondRaw is num) {
          diamondIds.add(legacyDiamondRaw.toInt());
        } else if (legacyDiamondRaw != null) {
          final parsed = int.tryParse(legacyDiamondRaw.toString());
          if (parsed != null) {
            diamondIds.add(parsed);
          }
        }
      }

      final restoredCount = await txn.update(
        'sales',
        {'deleted_at': null},
        where: 'id = ?',
        whereArgs: [id],
      );

      if (restoredCount > 0) {
        for (final diamondId in diamondIds) {
          final cnt = await _countDiamondReferences(txn, diamondId);
          if (cnt > 0) {
            await txn.update(
              'diamonds',
              {'status': 'sold'},
              where: 'id = ?',
              whereArgs: [diamondId],
            );
          }
        }
      }

      return restoredCount;
    });
  }

  Future<int> hardDelete(int id) async {
    final db = await _db.database;
    await _ensureSaleItemsSchema(db);
    await _ensureSalesBillNo(db);
    await _ensureSalesSoftDelete(db);
    return db.transaction<int>((txn) async {
      final legacySaleRows = await txn.query(
        'sales',
        columns: ['diamond_id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      final rows = await txn.query(
        'sale_items',
        columns: ['diamond_id'],
        where: 'sale_id = ?',
        whereArgs: [id],
      );
      final diamondIds = rows
          .map((r) => r['diamond_id'])
          .whereType<num>()
          .map((n) => n.toInt())
          .toSet();

      if (legacySaleRows.isNotEmpty) {
        final legacyDiamondRaw = legacySaleRows.first['diamond_id'];
        if (legacyDiamondRaw is num) {
          diamondIds.add(legacyDiamondRaw.toInt());
        } else if (legacyDiamondRaw != null) {
          final parsed = int.tryParse(legacyDiamondRaw.toString());
          if (parsed != null) {
            diamondIds.add(parsed);
          }
        }
      }

      await txn.delete('sale_items', where: 'sale_id = ?', whereArgs: [id]);
      final deletedCount = await txn.delete('sales', where: 'id = ?', whereArgs: [id]);

      if (deletedCount > 0) {
        for (final diamondId in diamondIds) {
          final cnt = await _countDiamondReferences(txn, diamondId);
          if (cnt == 0) {
            await txn.update(
              'diamonds',
              {'status': 'completed'},
              where: 'id = ?',
              whereArgs: [diamondId],
            );
          }
        }
      }

      return deletedCount;
    });
  }

  Future<double> totalRevenue() async {
    final db = await _db.database;
    await _ensureSalesSoftDelete(db);
    final result = await db.rawQuery(
      'SELECT SUM(price) as total FROM sales WHERE deleted_at IS NULL',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> countSales() async {
    final db = await _db.database;
    await _ensureSalesSoftDelete(db);
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM sales WHERE deleted_at IS NULL',
    );
    return result.first['cnt'] as int;
  }

  Future<List<Map<String, dynamic>>> monthlySales(int months) async {
    final db = await _db.database;
    await _ensureSalesSoftDelete(db);
    final rows = await db.rawQuery('''
      SELECT strftime('%Y-%m', date) as month, SUM(price) as total
      FROM sales
      WHERE deleted_at IS NULL AND date >= date('now', 'start of month', ?)
      GROUP BY strftime('%Y-%m', date)
      ORDER BY month ASC
    ''', ['-${months - 1} months']);
    return rows
        .map(
          (row) => {
            'month': row['month'] as String,
            'total': (row['total'] as num?)?.toDouble() ?? 0.0,
          },
        )
        .toList();
  }
}

// Implementasi konkret [ITransactionRepository] menggunakan SQLite.
//
// Operasi simpan transaksi menggunakan DB transaction atomik:
// jika salah satu langkah gagal (header / item / kurangi stok),
// seluruh operasi di-rollback untuk menjaga integritas data.
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/db_constants.dart';
import '../../core/database/database_helper.dart';
import '../../core/errors/app_exception.dart' as app_errors;
import '../../domain/repositories/i_transaction_repository.dart';
import '../models/transaction_item_model.dart';
import '../models/transaction_model.dart';

class TransactionRepository implements ITransactionRepository {
  TransactionRepository({DatabaseHelper? dbHelper})
      : _db = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _db;
  final _uuid = const Uuid();

  @override
  Future<TransactionModel> saveTransaction(TransactionModel transaction) async {
    try {
      final now = DateTime.now();
      final txId = _uuid.v4();

      final savedItems = transaction.items.map((item) {
        return item.copyWith(
          id: _uuid.v4(),
          transactionId: txId,
        );
      }).toList();

      final savedTransaction = transaction.copyWith(
        id: txId,
        createdAt: now,
        items: savedItems,
      );

      // Jalankan semua operasi dalam satu transaksi DB atomik
      await _db.runInTransaction((txn) async {
        // 1. Simpan header transaksi
        await txn.insert(
          DbConstants.tableTransactions,
          savedTransaction.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // 2. Simpan setiap item transaksi
        for (final item in savedItems) {
          await txn.insert(
            DbConstants.tableTransactionItems,
            item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // 3. Kurangi stok produk terkait
          await txn.rawUpdate(
            '''UPDATE ${DbConstants.tableProducts}
               SET ${DbConstants.colProductStock} = ${DbConstants.colProductStock} - ?,
                   ${DbConstants.colProductUpdatedAt} = ?
               WHERE ${DbConstants.colProductId} = ?''',
            [item.quantity, now.toIso8601String(), item.productId],
          );
        }
      });

      return savedTransaction;
    } catch (e) {
      if (e is app_errors.AppException) rethrow;
      throw app_errors.DatabaseException(
        'Gagal menyimpan transaksi',
        originalError: e,
      );
    }
  }

  @override
  Future<List<TransactionModel>> getByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final start = startDate.toIso8601String();
      final end = endDate.toIso8601String();

      final rows = await _db.queryAll(
        DbConstants.tableTransactions,
        where:
            '${DbConstants.colTransactionCreatedAt} BETWEEN ? AND ? AND ${DbConstants.colTransactionType} = ?',
        whereArgs: [start, end, 'income'],
        orderBy: '${DbConstants.colTransactionCreatedAt} DESC',
      );

      // Load items untuk setiap transaksi
      final transactions = <TransactionModel>[];
      for (final row in rows) {
        final items = await _getItemsByTransactionId(
          row[DbConstants.colTransactionId] as String,
        );
        transactions.add(TransactionModel.fromMap(row, items: items));
      }
      return transactions;
    } catch (e) {
      throw app_errors.DatabaseException(
        'Gagal mengambil data transaksi',
        originalError: e,
      );
    }
  }

  @override
  Future<TransactionModel?> getById(String id) async {
    try {
      final rows = await _db.queryAll(
        DbConstants.tableTransactions,
        where: '${DbConstants.colTransactionId} = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final items = await _getItemsByTransactionId(id);
      return TransactionModel.fromMap(rows.first, items: items);
    } catch (e) {
      throw app_errors.DatabaseException(
        'Gagal mengambil transaksi',
        originalError: e,
      );
    }
  }

  @override
  Future<int> getTotalIncomeByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return getTotalIncomeByDateRange(start, end);
  }

  @override
  Future<int> getTotalIncomeByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final result = await _db.rawQuery(
        '''SELECT COALESCE(SUM(${DbConstants.colTransactionTotalAmount}), 0) as total
           FROM ${DbConstants.tableTransactions}
           WHERE ${DbConstants.colTransactionCreatedAt} BETWEEN ? AND ?
             AND ${DbConstants.colTransactionType} = 'income' ''',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );
      final raw = result.first['total'];
      return raw is num ? raw.toInt() : 0;
    } catch (e) {
      throw app_errors.DatabaseException(
        'Gagal menghitung total pendapatan',
        originalError: e,
      );
    }
  }

  @override
  Future<int> getTotalProfitByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final result = await _db.rawQuery(
        '''SELECT COALESCE(
              SUM((ti.${DbConstants.colTxItemSellingPriceAtTime} -
                   ti.${DbConstants.colTxItemPurchasePriceAtTime}) *
                   ti.${DbConstants.colTxItemQuantity}), 0
            ) as total_profit
           FROM ${DbConstants.tableTransactionItems} ti
           INNER JOIN ${DbConstants.tableTransactions} t
             ON ti.${DbConstants.colTxItemTransactionId} = t.${DbConstants.colTransactionId}
           WHERE t.${DbConstants.colTransactionCreatedAt} BETWEEN ? AND ?
             AND t.${DbConstants.colTransactionType} = 'income' ''',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );
      final raw = result.first['total_profit'];
      return raw is num ? raw.toInt() : 0;
    } catch (e) {
      throw app_errors.DatabaseException(
        'Gagal menghitung total keuntungan',
        originalError: e,
      );
    }
  }

  @override
  Future<List<TransactionModel>> getRecent({int limit = 5}) async {
    try {
      final rows = await _db.queryAll(
        DbConstants.tableTransactions,
        orderBy: '${DbConstants.colTransactionCreatedAt} DESC',
        limit: limit,
      );
      final transactions = <TransactionModel>[];
      for (final row in rows) {
        final items = await _getItemsByTransactionId(
          row[DbConstants.colTransactionId] as String,
        );
        transactions.add(TransactionModel.fromMap(row, items: items));
      }
      return transactions;
    } catch (e) {
      throw app_errors.DatabaseException(
        'Gagal mengambil transaksi terbaru',
        originalError: e,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────

  Future<List<TransactionItemModel>> _getItemsByTransactionId(
    String transactionId,
  ) async {
    final rows = await _db.rawQuery(
      '''SELECT ti.*, p.${DbConstants.colProductName} as product_name
         FROM ${DbConstants.tableTransactionItems} ti
         LEFT JOIN ${DbConstants.tableProducts} p
           ON ti.${DbConstants.colTxItemProductId} = p.${DbConstants.colProductId}
         WHERE ti.${DbConstants.colTxItemTransactionId} = ?''',
      [transactionId],
    );
    return rows.map(TransactionItemModel.fromMap).toList();
  }
}

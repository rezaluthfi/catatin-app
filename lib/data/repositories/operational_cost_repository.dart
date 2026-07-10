import 'package:uuid/uuid.dart';

import '../../core/constants/db_constants.dart';
import '../../core/database/database_helper.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/repositories/i_operational_cost_repository.dart';
import '../models/operational_cost_model.dart';

class OperationalCostRepository implements IOperationalCostRepository {
  OperationalCostRepository({DatabaseHelper? dbHelper})
      : _db = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _db;
  final _uuid = const Uuid();

  @override
  Future<List<OperationalCostModel>> getAll() async {
    try {
      final rows = await _db.queryAll(
        DbConstants.tableOperationalCosts,
        orderBy: '${DbConstants.colCostDate} DESC, ${DbConstants.colCostCreatedAt} DESC',
      );
      return rows.map(OperationalCostModel.fromMap).toList();
    } catch (e) {
      throw DatabaseException('Gagal mengambil pengeluaran operasional', originalError: e);
    }
  }

  @override
  Future<List<OperationalCostModel>> getByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final start = startDate.toIso8601String();
      final end = endDate.toIso8601String();

      final rows = await _db.queryAll(
        DbConstants.tableOperationalCosts,
        where: '${DbConstants.colCostDate} BETWEEN ? AND ?',
        whereArgs: [start, end],
        orderBy: '${DbConstants.colCostDate} DESC',
      );
      return rows.map(OperationalCostModel.fromMap).toList();
    } catch (e) {
      throw DatabaseException('Gagal mengambil data pengeluaran', originalError: e);
    }
  }

  @override
  Future<OperationalCostModel> insert(OperationalCostModel cost) async {
    try {
      final now = DateTime.now();
      final newCost = cost.copyWith(
        id: _uuid.v4(),
        createdAt: now,
      );
      await _db.insert(DbConstants.tableOperationalCosts, newCost.toMap());
      return newCost;
    } catch (e) {
      throw DatabaseException('Gagal menyimpan pengeluaran', originalError: e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _db.delete(
        DbConstants.tableOperationalCosts,
        where: '${DbConstants.colCostId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Gagal menghapus pengeluaran', originalError: e);
    }
  }

  @override
  Future<int> getTotalByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return getTotalByDateRange(start, end);
  }

  @override
  Future<int> getTotalByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final result = await _db.rawQuery(
        '''SELECT COALESCE(SUM(${DbConstants.colCostAmount}), 0) as total
           FROM ${DbConstants.tableOperationalCosts}
           WHERE ${DbConstants.colCostDate} BETWEEN ? AND ?''',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );
      final raw = result.first['total'];
      return raw is num ? raw.toInt() : 0;
    } catch (e) {
      throw DatabaseException('Gagal menghitung total pengeluaran', originalError: e);
    }
  }
}

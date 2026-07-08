/// Implementasi konkret [IReceivableRepository] menggunakan SQLite.
import 'package:uuid/uuid.dart';

import '../../core/constants/db_constants.dart';
import '../../core/database/database_helper.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/repositories/i_receivable_repository.dart';
import '../models/receivable_model.dart';

class ReceivableRepository implements IReceivableRepository {
  ReceivableRepository({DatabaseHelper? dbHelper})
      : _db = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _db;
  final _uuid = const Uuid();

  @override
  Future<List<ReceivableModel>> getActive() async {
    try {
      final rows = await _db.queryAll(
        DbConstants.tableReceivables,
        where:
            "${DbConstants.colReceivableStatus} IN ('unpaid', 'partial')",
        orderBy: '${DbConstants.colReceivableCreatedAt} DESC',
      );
      return rows.map(ReceivableModel.fromMap).toList();
    } catch (e) {
      throw DatabaseException('Gagal mengambil piutang aktif', originalError: e);
    }
  }

  @override
  Future<List<ReceivableModel>> getAll() async {
    try {
      final rows = await _db.queryAll(
        DbConstants.tableReceivables,
        orderBy: '${DbConstants.colReceivableCreatedAt} DESC',
      );
      return rows.map(ReceivableModel.fromMap).toList();
    } catch (e) {
      throw DatabaseException('Gagal mengambil semua piutang', originalError: e);
    }
  }

  @override
  Future<ReceivableModel> insert(ReceivableModel receivable) async {
    try {
      final now = DateTime.now();
      final newReceivable = receivable.copyWith(
        id: _uuid.v4(),
        createdAt: now,
        updatedAt: now,
      );
      await _db.insert(DbConstants.tableReceivables, newReceivable.toMap());
      return newReceivable;
    } catch (e) {
      throw DatabaseException('Gagal menambah piutang', originalError: e);
    }
  }

  @override
  Future<void> markAsPaid(String id) async {
    try {
      // Ambil data piutang untuk mengetahui total amount
      final rows = await _db.queryAll(
        DbConstants.tableReceivables,
        where: '${DbConstants.colReceivableId} = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) throw NotFoundException('Piutang tidak ditemukan');
      final receivable = ReceivableModel.fromMap(rows.first);

      await _db.update(
        DbConstants.tableReceivables,
        {
          DbConstants.colReceivablePaidAmount: receivable.amount,
          DbConstants.colReceivableStatus: ReceivableStatus.paid.value,
          DbConstants.colReceivableUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '${DbConstants.colReceivableId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Gagal menandai piutang sebagai lunas',
          originalError: e);
    }
  }

  @override
  Future<void> addPartialPayment(String id, int paidAmount) async {
    try {
      final rows = await _db.queryAll(
        DbConstants.tableReceivables,
        where: '${DbConstants.colReceivableId} = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) throw NotFoundException('Piutang tidak ditemukan');
      final receivable = ReceivableModel.fromMap(rows.first);

      final newPaidAmount = receivable.paidAmount + paidAmount;
      final newStatus = newPaidAmount >= receivable.amount
          ? ReceivableStatus.paid
          : ReceivableStatus.partial;

      await _db.update(
        DbConstants.tableReceivables,
        {
          DbConstants.colReceivablePaidAmount: newPaidAmount,
          DbConstants.colReceivableStatus: newStatus.value,
          DbConstants.colReceivableUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '${DbConstants.colReceivableId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Gagal mencatat pembayaran', originalError: e);
    }
  }

  @override
  Future<int> getTotalOutstanding() async {
    try {
      final result = await _db.rawQuery(
        '''SELECT COALESCE(
              SUM(${DbConstants.colReceivableAmount} - ${DbConstants.colReceivablePaidAmount}),
              0
           ) as total
           FROM ${DbConstants.tableReceivables}
           WHERE ${DbConstants.colReceivableStatus} IN ('unpaid', 'partial')''',
      );
      return (result.first['total'] as int?) ?? 0;
    } catch (e) {
      throw DatabaseException('Gagal menghitung total piutang', originalError: e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _db.delete(
        DbConstants.tableReceivables,
        where: '${DbConstants.colReceivableId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Gagal menghapus piutang', originalError: e);
    }
  }
}

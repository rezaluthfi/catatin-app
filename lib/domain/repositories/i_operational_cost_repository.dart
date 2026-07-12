import '../../data/models/operational_cost_model.dart';

abstract interface class IOperationalCostRepository {
  /// Ambil semua biaya operasional, diurutkan dari yang terbaru.
  Future<List<OperationalCostModel>> getAll();

  /// Ambil biaya operasional berdasarkan rentang tanggal.
  Future<List<OperationalCostModel>> getByDateRange(DateTime startDate, DateTime endDate);

  /// Tambah biaya operasional baru.
  Future<OperationalCostModel> insert(OperationalCostModel cost);

  /// Ubah biaya operasional.
  Future<void> update(OperationalCostModel cost);

  /// Hapus biaya operasional berdasarkan ID.
  Future<void> delete(String id);

  /// Ambil total pengeluaran operasional hari ini.
  Future<int> getTotalByDate(DateTime date);

  /// Ambil total pengeluaran operasional dalam rentang tanggal.
  Future<int> getTotalByDateRange(DateTime startDate, DateTime endDate);
}

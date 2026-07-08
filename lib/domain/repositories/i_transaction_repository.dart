/// Interface (kontrak) untuk repository Transaksi.
import '../../data/models/transaction_model.dart';

abstract interface class ITransactionRepository {
  /// Simpan transaksi baru beserta semua item-nya dalam satu transaksi DB atomik.
  Future<TransactionModel> saveTransaction(TransactionModel transaction);

  /// Ambil semua transaksi dalam rentang tanggal tertentu.
  Future<List<TransactionModel>> getByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Ambil transaksi berdasarkan ID (beserta item-itemnya).
  Future<TransactionModel?> getById(String id);

  /// Ambil ringkasan kas masuk pada hari tertentu.
  Future<int> getTotalIncomeByDate(DateTime date);

  /// Ambil ringkasan kas masuk dalam rentang tanggal.
  Future<int> getTotalIncomeByDateRange(DateTime startDate, DateTime endDate);

  /// Ambil total keuntungan kotor dalam rentang tanggal.
  Future<int> getTotalProfitByDateRange(DateTime startDate, DateTime endDate);

  /// Ambil daftar transaksi terbaru (untuk ditampilkan di dashboard).
  Future<List<TransactionModel>> getRecent({int limit = 5});
}

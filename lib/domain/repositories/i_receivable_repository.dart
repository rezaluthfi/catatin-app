/// Interface (kontrak) untuk repository Piutang.
import '../../data/models/receivable_model.dart';

abstract interface class IReceivableRepository {
  /// Ambil semua piutang aktif (status unpaid atau partial).
  Future<List<ReceivableModel>> getActive();

  /// Ambil semua piutang (termasuk yang sudah lunas).
  Future<List<ReceivableModel>> getAll();

  /// Tambah catatan piutang baru.
  Future<ReceivableModel> insert(ReceivableModel receivable);

  /// Tandai piutang sebagai lunas penuh.
  Future<void> markAsPaid(String id);

  /// Catat pembayaran sebagian (cicilan).
  Future<void> addPartialPayment(String id, int paidAmount);

  /// Ambil total keseluruhan piutang yang belum tertagih.
  Future<int> getTotalOutstanding();

  /// Ambil total piutang yang dibuat dalam rentang tanggal tertentu
  /// (digunakan untuk rekap arus kas per bulan).
  Future<int> getTotalByDateRange(DateTime start, DateTime end);

  /// Reset status pembayaran piutang kembali ke belum lunas.
  Future<void> resetPayment(String id);

  /// Hapus piutang berdasarkan ID.
  Future<void> delete(String id);
}

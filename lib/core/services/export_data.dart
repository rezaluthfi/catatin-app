import '../../data/models/product_model.dart';
import '../../data/models/product_stock_history_model.dart';
import '../../data/models/operational_cost_model.dart';
import '../../data/models/receivable_model.dart';
import '../../data/models/transaction_model.dart';

class ExportData {
  const ExportData({
    required this.businessName,
    required this.ownerName,
    required this.startDate,
    required this.endDate,
    required this.transactions,
    required this.operationalCosts,
    required this.receivables,
    this.products = const [],
    this.stockHistory = const [],
  });

  final String businessName;
  final String ownerName;
  final DateTime startDate;
  final DateTime endDate;
  final List<TransactionModel> transactions;
  final List<OperationalCostModel> operationalCosts;
  final List<ReceivableModel> receivables;
  final List<ProductModel> products;
  final List<ProductStockHistoryModel> stockHistory;

  /// Total pemasukan dari semua transaksi.
  int get totalRevenue =>
      transactions.fold(0, (sum, t) => sum + t.totalAmount);

  /// Total pengeluaran operasional.
  int get totalOperationalCost =>
      operationalCosts.fold(0, (sum, c) => sum + c.amount);

  /// Total Harga Pokok Penjualan (HPP) berdasarkan modal barang yang terjual.
  int get totalHpp => transactions.fold(
        0,
        (sum, t) => sum + t.items.fold(
              0,
              (itemSum, item) => itemSum + (item.purchasePriceAtTime * item.quantity),
            ),
      );

  /// Nilai Persediaan Awal (Awal Periode).
  int get initialInventoryValue {
    int total = 0;
    for (final p in products) {
      // Perubahan stok setelah tanggal mulai periode
      final adjustmentsAfterStart = stockHistory
          .where((h) => h.productId == p.id && h.date.isAfter(startDate))
          .fold(0, (sum, h) => sum + h.stockAdded);

      // Penjualan setelah tanggal mulai periode
      final salesAfterStart = transactions
          .where((t) => t.createdAt.isAfter(startDate))
          .fold(0, (sum, t) => sum + t.items
              .where((item) => item.productId == p.id)
              .fold(0, (itemSum, item) => itemSum + item.quantity));

      final initialStock = (p.stock - adjustmentsAfterStart + salesAfterStart).clamp(0, 999999);
      total += initialStock * p.purchasePrice;
    }
    return total;
  }

  /// Total Pembelian/Penambahan Stok Barang selama periode.
  int get purchasesValue {
    return stockHistory
        .where((h) => h.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            h.date.isBefore(endDate.add(const Duration(seconds: 1))) &&
            h.stockAdded > 0)
        .fold(0, (sum, h) => sum + (h.stockAdded * h.purchasePrice));
  }

  /// Nilai Persediaan Akhir (Akhir Periode) -> Awal + Pembelian - HPP.
  int get endingInventoryValue {
    return (initialInventoryValue + purchasesValue - totalHpp).clamp(0, 999999999);
  }

  /// Total laba bersih (pemasukan - HPP - biaya operasional).
  int get netProfit => totalRevenue - totalHpp - totalOperationalCost;

  /// Total piutang belum lunas.
  int get totalOutstandingReceivables => receivables
      .where((r) => !r.isPaid)
      .fold(0, (sum, r) => sum + r.remainingAmount);
}

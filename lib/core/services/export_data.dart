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

  /// Total Nilai Persediaan Barang (Total Stok x Harga Beli).
  int get totalInventoryValue {
    return products.fold(0, (sum, p) => sum + (p.stock * p.purchasePrice));
  }

  /// Total laba bersih (pemasukan - HPP - biaya operasional).
  int get netProfit => totalRevenue - totalHpp - totalOperationalCost;

  /// Total piutang belum lunas.
  int get totalOutstandingReceivables => receivables
      .where((r) => !r.isPaid)
      .fold(0, (sum, r) => sum + r.remainingAmount);
}

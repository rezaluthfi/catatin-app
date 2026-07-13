/// Data container untuk proses ekspor laporan.
///
/// Dikumpulkan sekali lalu diteruskan ke [ExportService].
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
  });

  final String businessName;
  final String ownerName;
  final DateTime startDate;
  final DateTime endDate;
  final List<TransactionModel> transactions;
  final List<OperationalCostModel> operationalCosts;
  final List<ReceivableModel> receivables;

  /// Total pemasukan dari semua transaksi.
  int get totalRevenue =>
      transactions.fold(0, (sum, t) => sum + t.totalAmount);

  /// Total pengeluaran operasional.
  int get totalOperationalCost =>
      operationalCosts.fold(0, (sum, c) => sum + c.amount);

  /// Total laba bersih (pemasukan - biaya operasional).
  int get netProfit => totalRevenue - totalOperationalCost;

  /// Total piutang belum lunas.
  int get totalOutstandingReceivables => receivables
      .where((r) => !r.isPaid)
      .fold(0, (sum, r) => sum + r.remainingAmount);
}

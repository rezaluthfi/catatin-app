import '../../../data/models/operational_cost_model.dart';
import '../../../data/models/transaction_model.dart';

enum RecapPeriod {
  daily('Harian'),
  weekly('Mingguan'),
  monthly('Bulanan');

  const RecapPeriod(this.label);
  final String label;
}

class RecapState {
  const RecapState({
    required this.selectedDate,
    this.period = RecapPeriod.daily,
    this.totalRevenue = 0,
    this.totalCOGS = 0,
    this.totalOperationalCost = 0,
    this.grossProfit = 0,
    this.netProfit = 0,
    this.operationalCosts = const [],
    this.chartData = const {},
    this.soldProducts = const [],
    this.transactions = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final DateTime selectedDate;
  final RecapPeriod period;
  final int totalRevenue;           // Omzet
  final int totalCOGS;              // HPP
  final int totalOperationalCost;   // Biaya Operasional
  final int grossProfit;            // Laba Kotor
  final int netProfit;              // Laba Bersih
  final List<OperationalCostModel> operationalCosts;
  
  // Tanggal -> (Omzet, Laba Bersih)
  final Map<String, ({int revenue, int netProfit})> chartData;

  // Produk Terjual: (Nama, Kuantitas, Subtotal)
  final List<({String name, int quantity, int totalAmount})> soldProducts;

  // Daftar Transaksi dalam periode
  final List<TransactionModel> transactions;
  
  final bool isLoading;
  final String? errorMessage;

  RecapState copyWith({
    DateTime? selectedDate,
    RecapPeriod? period,
    int? totalRevenue,
    int? totalCOGS,
    int? totalOperationalCost,
    int? grossProfit,
    int? netProfit,
    List<OperationalCostModel>? operationalCosts,
    Map<String, ({int revenue, int netProfit})>? chartData,
    List<({String name, int quantity, int totalAmount})>? soldProducts,
    List<TransactionModel>? transactions,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RecapState(
      selectedDate: selectedDate ?? this.selectedDate,
      period: period ?? this.period,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalCOGS: totalCOGS ?? this.totalCOGS,
      totalOperationalCost: totalOperationalCost ?? this.totalOperationalCost,
      grossProfit: grossProfit ?? this.grossProfit,
      netProfit: netProfit ?? this.netProfit,
      operationalCosts: operationalCosts ?? this.operationalCosts,
      chartData: chartData ?? this.chartData,
      soldProducts: soldProducts ?? this.soldProducts,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

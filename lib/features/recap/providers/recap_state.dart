import '../../../data/models/operational_cost_model.dart';
import '../../../data/models/transaction_model.dart';

enum RecapPeriod {
  daily('Harian'),
  weekly('Mingguan'),
  monthly('Bulanan');

  const RecapPeriod(this.label);
  final String label;
}

/// Skala waktu untuk grafik Tren Keuangan.
enum ChartScale {
  week7('7H'),
  month1('1B'),
  month3('3B'),
  month6('6B');

  const ChartScale(this.label);
  final String label;
}

// Sentinel untuk membedakan "tidak di-pass" vs "di-pass sebagai null"
const _undefined = Object();

class RecapState {
  const RecapState({
    required this.selectedDate,
    this.selectedEndDate,
    this.period = RecapPeriod.daily,
    this.totalRevenue = 0,
    this.totalCOGS = 0,
    this.totalOperationalCost = 0,
    this.grossProfit = 0,
    this.netProfit = 0,
    this.operationalCosts = const [],
    this.chartData = const {},
    this.chartScale = ChartScale.month6,
    this.soldProducts = const [],
    this.transactions = const [],
    this.totalReceivables = 0,
    this.totalInventoryValue = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  final DateTime selectedDate;

  /// Tanggal akhir rentang (hanya digunakan untuk mode Mingguan custom).
  final DateTime? selectedEndDate;

  final RecapPeriod period;
  final int totalRevenue;           // Omzet
  final int totalCOGS;              // HPP
  final int totalOperationalCost;   // Biaya Operasional
  final int grossProfit;            // Laba Kotor
  final int netProfit;              // Laba Bersih
  final List<OperationalCostModel> operationalCosts;

  // Tanggal -> (Omzet, Laba Bersih) untuk grafik
  final Map<String, ({int revenue, int netProfit})> chartData;

  /// Skala waktu tampilan grafik Tren Keuangan.
  final ChartScale chartScale;

  // Produk Terjual: (Nama, Kuantitas, Subtotal)
  final List<({String name, int quantity, int totalAmount})> soldProducts;

  // Daftar Transaksi dalam periode
  final List<TransactionModel> transactions;

  /// Total piutang (kasbon) yang dibuat dalam periode aktif.
  final int totalReceivables;

  /// Total nilai persediaan barang berdasarkan harga beli × stok saat ini.
  final int totalInventoryValue;

  final bool isLoading;
  final String? errorMessage;

  RecapState copyWith({
    DateTime? selectedDate,
    // Gunakan sentinel agar bisa di-set ke null secara eksplisit
    Object? selectedEndDate = _undefined,
    RecapPeriod? period,
    int? totalRevenue,
    int? totalCOGS,
    int? totalOperationalCost,
    int? grossProfit,
    int? netProfit,
    List<OperationalCostModel>? operationalCosts,
    Map<String, ({int revenue, int netProfit})>? chartData,
    ChartScale? chartScale,
    List<({String name, int quantity, int totalAmount})>? soldProducts,
    List<TransactionModel>? transactions,
    int? totalReceivables,
    int? totalInventoryValue,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RecapState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedEndDate: identical(selectedEndDate, _undefined)
          ? this.selectedEndDate
          : selectedEndDate as DateTime?,
      period: period ?? this.period,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalCOGS: totalCOGS ?? this.totalCOGS,
      totalOperationalCost: totalOperationalCost ?? this.totalOperationalCost,
      grossProfit: grossProfit ?? this.grossProfit,
      netProfit: netProfit ?? this.netProfit,
      operationalCosts: operationalCosts ?? this.operationalCosts,
      chartData: chartData ?? this.chartData,
      chartScale: chartScale ?? this.chartScale,
      soldProducts: soldProducts ?? this.soldProducts,
      transactions: transactions ?? this.transactions,
      totalReceivables: totalReceivables ?? this.totalReceivables,
      totalInventoryValue: totalInventoryValue ?? this.totalInventoryValue,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

import '../../../data/models/product_model.dart';
import '../../../data/models/transaction_model.dart';

class DashboardChartPoint {
  const DashboardChartPoint({
    required this.date,
    required this.income,
    required this.netProfit,
  });

  final DateTime date;
  final int income;
  final int netProfit;
}

class DashboardState {
  const DashboardState({
    this.businessName = 'Toko UMKM',
    this.incomeToday = 0,
    this.expenseToday = 0,
    this.netProfitToday = 0,
    this.receivablesOutstanding = 0,
    this.lowStockProducts = const [],
    this.recentTransactions = const [],
    this.weeklyTrend = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final String businessName;
  final int incomeToday;
  final int expenseToday;
  final int netProfitToday;
  final int receivablesOutstanding;
  final List<ProductModel> lowStockProducts;
  final List<TransactionModel> recentTransactions;
  final List<DashboardChartPoint> weeklyTrend;
  final bool isLoading;
  final String? errorMessage;

  DashboardState copyWith({
    String? businessName,
    int? incomeToday,
    int? expenseToday,
    int? netProfitToday,
    int? receivablesOutstanding,
    List<ProductModel>? lowStockProducts,
    List<TransactionModel>? recentTransactions,
    List<DashboardChartPoint>? weeklyTrend,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DashboardState(
      businessName: businessName ?? this.businessName,
      incomeToday: incomeToday ?? this.incomeToday,
      expenseToday: expenseToday ?? this.expenseToday,
      netProfitToday: netProfitToday ?? this.netProfitToday,
      receivablesOutstanding: receivablesOutstanding ?? this.receivablesOutstanding,
      lowStockProducts: lowStockProducts ?? this.lowStockProducts,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      weeklyTrend: weeklyTrend ?? this.weeklyTrend,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

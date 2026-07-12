import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../auth/providers/auth_provider.dart';
import 'dashboard_state.dart';

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);

class DashboardNotifier extends AsyncNotifier<DashboardState> {
  @override
  FutureOr<DashboardState> build() async {
    return _loadData();
  }

  Future<DashboardState> _loadData() async {
    final txRepo = ref.read(transactionRepositoryProvider);
    final opRepo = ref.read(operationalCostRepositoryProvider);
    final recRepo = ref.read(receivableRepositoryProvider);
    final prodRepo = ref.read(productRepositoryProvider);

    final settingsRepo = ref.read(settingsRepositoryProvider);

    try {
      final now = DateTime.now();
      
      // Ambil Nama Usaha
      final settings = await settingsRepo.getSettings();
      final businessName = settings.businessName.isEmpty ? 'Toko UMKM' : settings.businessName;

      final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Ambil Pemasukan Hari Ini
      final income = await txRepo.getTotalIncomeByDate(now);
      
      // Ambil Pengeluaran Hari Ini
      final expense = await opRepo.getTotalByDate(now);
      
      // Hitung Laba Bersih Hari Ini = Laba Kotor - Pengeluaran Operasional
      final grossProfit = await txRepo.getTotalProfitByDateRange(start, end);
      final netProfit = grossProfit - expense;

      // Ambil Total Piutang Aktif
      final outstanding = await recRepo.getTotalOutstanding();
      
      // Ambil Produk Stok Menipis (Threshold: 5)
      final lowStock = await prodRepo.getLowStockProducts(threshold: 5);

      // Ambil Transaksi Terbaru (Limit: 3)
      final recentTxs = await txRepo.getRecent(limit: 3);

      // Hitung data tren mingguan (7 hari terakhir)
      final List<DashboardChartPoint> weeklyTrend = [];
      for (int i = 6; i >= 0; i--) {
        final dayDate = now.subtract(Duration(days: i));
        final startOfDay = DateTime(dayDate.year, dayDate.month, dayDate.day, 0, 0, 0);
        final endOfDay = DateTime(dayDate.year, dayDate.month, dayDate.day, 23, 59, 59);

        final dayIncome = await txRepo.getTotalIncomeByDateRange(startOfDay, endOfDay);
        final dayGross = await txRepo.getTotalProfitByDateRange(startOfDay, endOfDay);
        final dayExpense = await opRepo.getTotalByDateRange(startOfDay, endOfDay);
        final dayNetProfit = dayGross - dayExpense;

        weeklyTrend.add(DashboardChartPoint(
          date: dayDate,
          income: dayIncome,
          netProfit: dayNetProfit,
        ));
      }

      return DashboardState(
        businessName: businessName,
        incomeToday: income,
        expenseToday: expense,
        netProfitToday: netProfit,
        receivablesOutstanding: outstanding,
        lowStockProducts: lowStock,
        recentTransactions: recentTxs,
        weeklyTrend: weeklyTrend,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      return DashboardState(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadData());
  }
}

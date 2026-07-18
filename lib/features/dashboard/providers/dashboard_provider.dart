import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_enums.dart';
import 'dashboard_state.dart';

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(
      DashboardNotifier.new,
    );

class DashboardNotifier extends AsyncNotifier<DashboardState> {
  @override
  FutureOr<DashboardState> build() async {
    return _loadData(DashboardPeriod.sevenDays);
  }

  Future<DashboardState> _loadData(DashboardPeriod period) async {
    final txRepo = ref.read(transactionRepositoryProvider);
    final opRepo = ref.read(operationalCostRepositoryProvider);
    final recRepo = ref.read(receivableRepositoryProvider);
    final prodRepo = ref.read(productRepositoryProvider);
    final settingsRepo = ref.read(settingsRepositoryProvider);

    try {
      final now = DateTime.now();

      // Ambil Nama Usaha
      final settings = await settingsRepo.getSettings();
      final businessName = settings.businessName.isEmpty
          ? 'Toko UMKM'
          : settings.businessName;

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

      // Ambil Transaksi Terbaru Hari Ini (Limit: 3)
      final todayTxs = await txRepo.getByDateRange(start, end);
      final recentTxs = (List<TransactionModel>.from(todayTxs)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
          .take(3)
          .toList();

      // Tentukan rentang waktu keseluruhan untuk pre-fetch data grafik
      final int loopCount;
      final DateTime entireStart;
      final DateTime entireEnd = end;

      if (period == DashboardPeriod.sevenDays) {
        loopCount = 7;
        entireStart = DateTime(now.year, now.month, now.day - 6, 0, 0, 0);
      } else if (period == DashboardPeriod.oneMonth) {
        loopCount = 30;
        entireStart = DateTime(now.year, now.month, now.day - 29, 0, 0, 0);
      } else if (period == DashboardPeriod.threeMonths) {
        loopCount = 12; // 12 weeks
        final startOfWeek = now.subtract(const Duration(days: 12 * 7 - 1));
        entireStart = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
          0,
          0,
          0,
        );
      } else {
        loopCount = 6; // 6 months
        final monthDate = DateTime(now.year, now.month - 5, 1);
        entireStart = DateTime(monthDate.year, monthDate.month, 1, 0, 0, 0);
      }

      // Pre-fetch semua data grafik dalam satu kali query (Optimasi Performa)
      final allRangeTxs = await txRepo.getByDateRange(entireStart, entireEnd);
      final allRangeCosts = await opRepo.getByDateRange(entireStart, entireEnd);
      final allReceivables = await recRepo.getAll();

      final List<DashboardChartPoint> weeklyTrend = [];
      final Map<int, String> dayNames = {
        1: 'Sn',
        2: 'Sl',
        3: 'Rb',
        4: 'Km',
        5: 'Jm',
        6: 'Sb',
        7: 'Mg',
      };

      final monthNames = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];

      for (int i = loopCount - 1; i >= 0; i--) {
        DateTime startRange;
        DateTime endRange;
        String pointLabel;

        if (period == DashboardPeriod.sevenDays) {
          final date = now.subtract(Duration(days: i));
          startRange = DateTime(date.year, date.month, date.day, 0, 0, 0);
          endRange = DateTime(date.year, date.month, date.day, 23, 59, 59);
          pointLabel = dayNames[date.weekday] ?? '';
        } else if (period == DashboardPeriod.oneMonth) {
          final date = now.subtract(Duration(days: i));
          startRange = DateTime(date.year, date.month, date.day, 0, 0, 0);
          endRange = DateTime(date.year, date.month, date.day, 23, 59, 59);
          pointLabel = date.day.toString();
        } else if (period == DashboardPeriod.threeMonths) {
          final endOfWeek = now.subtract(Duration(days: i * 7));
          final startOfWeek = now.subtract(Duration(days: i * 7 + 6));
          startRange = DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
            0,
            0,
            0,
          );
          endRange = DateTime(
            endOfWeek.year,
            endOfWeek.month,
            endOfWeek.day,
            23,
            59,
            59,
          );
          pointLabel = 'M${12 - i}';
        } else {
          final monthDate = DateTime(now.year, now.month - i, 1);
          startRange = DateTime(monthDate.year, monthDate.month, 1, 0, 0, 0);
          endRange = DateTime(
            monthDate.year,
            monthDate.month + 1,
            1,
          ).subtract(const Duration(seconds: 1));
          pointLabel = monthNames[monthDate.month];
        }

        // Filter data di memori (sangat cepat dibandingkan roundtrip database query)
        final rangeTxs = allRangeTxs.where(
          (tx) =>
              tx.createdAt.isAfter(
                startRange.subtract(const Duration(seconds: 1)),
              ) &&
              tx.createdAt.isBefore(endRange.add(const Duration(seconds: 1))),
        );

        int dayIncome = 0;
        int dayCash = 0;
        int dayGross = 0;

        for (final tx in rangeTxs) {
          dayIncome += tx.totalAmount;
          dayGross += tx.totalProfit;
          if (tx.paymentMethod != PaymentMethod.credit) {
            dayCash += tx.totalAmount;
          }
        }

        final rangeCosts = allRangeCosts.where(
          (c) =>
              c.date.isAfter(startRange.subtract(const Duration(seconds: 1))) &&
              c.date.isBefore(endRange.add(const Duration(seconds: 1))),
        );
        final dayExpense = rangeCosts.fold<int>(0, (sum, c) => sum + c.amount);

        final dayNetProfit = dayGross - dayExpense;

        // Query receivables created in range
        final rangeReceivables = allReceivables.where(
          (r) =>
              r.createdAt.isAfter(
                startRange.subtract(const Duration(seconds: 1)),
              ) &&
              r.createdAt.isBefore(endRange.add(const Duration(seconds: 1))),
        );
        final dayReceivables = rangeReceivables.fold<int>(
          0,
          (sum, r) => sum + r.amount,
        );

        weeklyTrend.add(
          DashboardChartPoint(
            label: pointLabel,
            date: startRange,
            income: dayIncome,
            netProfit: dayNetProfit,
            cash: dayCash,
            receivables: dayReceivables,
          ),
        );
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
        selectedPeriod: period,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      return DashboardState(
        isLoading: false,
        errorMessage: e.toString(),
        selectedPeriod: period,
      );
    }
  }

  Future<void> changePeriod(DashboardPeriod period) async {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = await AsyncValue.guard(
        () => _loadChartTrendOnly(period, currentState),
      );
    } else {
      state = await AsyncValue.guard(() => _loadData(period));
    }
  }

  Future<void> reload() async {
    final currentPeriod =
        state.valueOrNull?.selectedPeriod ?? DashboardPeriod.sevenDays;
    state = await AsyncValue.guard(() => _loadData(currentPeriod));
  }

  Future<DashboardState> _loadChartTrendOnly(
    DashboardPeriod period,
    DashboardState currentState,
  ) async {
    final txRepo = ref.read(transactionRepositoryProvider);
    final opRepo = ref.read(operationalCostRepositoryProvider);
    final recRepo = ref.read(receivableRepositoryProvider);

    final now = DateTime.now();
    final endToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final int loopCount;
    final DateTime entireStart;
    final DateTime entireEnd = endToday;

    if (period == DashboardPeriod.sevenDays) {
      loopCount = 7;
      entireStart = DateTime(now.year, now.month, now.day - 6, 0, 0, 0);
    } else if (period == DashboardPeriod.oneMonth) {
      loopCount = 30;
      entireStart = DateTime(now.year, now.month, now.day - 29, 0, 0, 0);
    } else if (period == DashboardPeriod.threeMonths) {
      loopCount = 12; // 12 weeks
      final startOfWeek = now.subtract(const Duration(days: 12 * 7 - 1));
      entireStart = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
        0,
        0,
        0,
      );
    } else {
      loopCount = 6; // 6 months
      final monthDate = DateTime(now.year, now.month - 5, 1);
      entireStart = DateTime(monthDate.year, monthDate.month, 1, 0, 0, 0);
    }

    final allRangeTxs = await txRepo.getByDateRange(entireStart, entireEnd);
    final allRangeCosts = await opRepo.getByDateRange(entireStart, entireEnd);
    final allReceivables = await recRepo.getAll();

    final List<DashboardChartPoint> weeklyTrend = [];
    final Map<int, String> dayNames = {
      1: 'Sn',
      2: 'Sl',
      3: 'Rb',
      4: 'Km',
      5: 'Jm',
      6: 'Sb',
      7: 'Mg',
    };
    final monthNames = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    for (int i = loopCount - 1; i >= 0; i--) {
      DateTime startRange;
      DateTime endRange;
      String pointLabel;

      if (period == DashboardPeriod.sevenDays) {
        final date = now.subtract(Duration(days: i));
        startRange = DateTime(date.year, date.month, date.day, 0, 0, 0);
        endRange = DateTime(date.year, date.month, date.day, 23, 59, 59);
        pointLabel = dayNames[date.weekday] ?? '';
      } else if (period == DashboardPeriod.oneMonth) {
        final date = now.subtract(Duration(days: i));
        startRange = DateTime(date.year, date.month, date.day, 0, 0, 0);
        endRange = DateTime(date.year, date.month, date.day, 23, 59, 59);
        pointLabel = date.day.toString();
      } else if (period == DashboardPeriod.threeMonths) {
        final endOfWeek = now.subtract(Duration(days: i * 7));
        final startOfWeek = now.subtract(Duration(days: i * 7 + 6));
        startRange = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
          0,
          0,
          0,
        );
        endRange = DateTime(
          endOfWeek.year,
          endOfWeek.month,
          endOfWeek.day,
          23,
          59,
          59,
        );
        pointLabel = 'M${12 - i}';
      } else {
        final monthDate = DateTime(now.year, now.month - i, 1);
        startRange = DateTime(monthDate.year, monthDate.month, 1, 0, 0, 0);
        endRange = DateTime(
          monthDate.year,
          monthDate.month + 1,
          1,
        ).subtract(const Duration(seconds: 1));
        pointLabel = monthNames[monthDate.month];
      }

      final rangeTxs = allRangeTxs.where(
        (tx) =>
            tx.createdAt.isAfter(
              startRange.subtract(const Duration(seconds: 1)),
            ) &&
            tx.createdAt.isBefore(endRange.add(const Duration(seconds: 1))),
      );

      int dayIncome = 0;
      int dayCash = 0;
      int dayGross = 0;

      for (final tx in rangeTxs) {
        dayIncome += tx.totalAmount;
        dayGross += tx.totalProfit;
        if (tx.paymentMethod != PaymentMethod.credit) {
          dayCash += tx.totalAmount;
        }
      }

      final rangeCosts = allRangeCosts.where(
        (c) =>
            c.date.isAfter(startRange.subtract(const Duration(seconds: 1))) &&
            c.date.isBefore(endRange.add(const Duration(seconds: 1))),
      );
      final dayExpense = rangeCosts.fold<int>(0, (sum, c) => sum + c.amount);

      final dayNetProfit = dayGross - dayExpense;

      final rangeReceivables = allReceivables.where(
        (r) =>
            r.createdAt.isAfter(
              startRange.subtract(const Duration(seconds: 1)),
            ) &&
            r.createdAt.isBefore(endRange.add(const Duration(seconds: 1))),
      );
      final dayReceivables = rangeReceivables.fold<int>(
        0,
        (sum, r) => sum + r.amount,
      );

      weeklyTrend.add(
        DashboardChartPoint(
          label: pointLabel,
          date: startRange,
          income: dayIncome,
          netProfit: dayNetProfit,
          cash: dayCash,
          receivables: dayReceivables,
        ),
      );
    }

    return currentState.copyWith(
      weeklyTrend: weeklyTrend,
      selectedPeriod: period,
    );
  }
}

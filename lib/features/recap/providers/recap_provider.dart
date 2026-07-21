import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../data/models/operational_cost_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import 'recap_state.dart';

final recapProvider = AsyncNotifierProvider<RecapNotifier, RecapState>(
  RecapNotifier.new,
);

class RecapNotifier extends AsyncNotifier<RecapState> {
  @override
  FutureOr<RecapState> build() async {
    return _loadData(RecapState(selectedDate: DateTime.now()));
  }

  /// Bangun data grafik berdasarkan [ChartScale] yang dipilih.
  /// Semua skala selalu relatif terhadap hari ini (DateTime.now()).
  Future<Map<String, ({int revenue, int netProfit})>> _buildChartData(
    ChartScale scale,
  ) async {
    final txRepo = ref.read(transactionRepositoryProvider);
    final opRepo = ref.read(operationalCostRepositoryProvider);
    final now = DateTime.now();
    final Map<String, ({int revenue, int netProfit})> chartData = {};

    // Tentukan jumlah loop
    final int loopCount;
    if (scale == ChartScale.week7) {
      loopCount = 7;
    } else if (scale == ChartScale.month1) {
      loopCount = 30;
    } else if (scale == ChartScale.month3) {
      loopCount = 12; // 12 minggu
    } else {
      loopCount = 6; // 6 bulan
    }

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

      if (scale == ChartScale.week7) {
        final date = now.subtract(Duration(days: i));
        startRange = DateTime(date.year, date.month, date.day, 0, 0, 0);
        endRange = DateTime(date.year, date.month, date.day, 23, 59, 59);
        pointLabel = dayNames[date.weekday] ?? '';
      } else if (scale == ChartScale.month1) {
        final date = now.subtract(Duration(days: i));
        startRange = DateTime(date.year, date.month, date.day, 0, 0, 0);
        endRange = DateTime(date.year, date.month, date.day, 23, 59, 59);
        pointLabel = '${date.day} ${monthNames[date.month]}';
      } else if (scale == ChartScale.month3) {
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

      final r = await txRepo.getTotalIncomeByDateRange(startRange, endRange);
      final g = await txRepo.getTotalProfitByDateRange(startRange, endRange);
      final o = await opRepo.getTotalByDateRange(startRange, endRange);
      final n = g - o;

      chartData[pointLabel] = (revenue: r, netProfit: n);
    }

    return chartData;
  }

  Future<RecapState> _loadData(RecapState currentState) async {
    final txRepo = ref.read(transactionRepositoryProvider);
    final opRepo = ref.read(operationalCostRepositoryProvider);
    final productRepo = ref.read(productRepositoryProvider);
    final receivableRepo = ref.read(receivableRepositoryProvider);

    try {
      final selectedDate = currentState.selectedDate;
      DateTime start;
      DateTime end;

      if (currentState.period == RecapPeriod.daily) {
        start = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          0,
          0,
          0,
        );
        end = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          23,
          59,
          59,
        );
      } else if (currentState.period == RecapPeriod.weekly) {
        // Gunakan selectedEndDate jika ada (dari date range picker),
        // fallback ke Senin-Minggu dari selectedDate
        final startDay = currentState.selectedDate;
        final endDay =
            currentState.selectedEndDate ??
            currentState.selectedDate.add(const Duration(days: 6));
        start = DateTime(startDay.year, startDay.month, startDay.day, 0, 0, 0);
        end = DateTime(endDay.year, endDay.month, endDay.day, 23, 59, 59);
      } else {
        // Monthly
        start = DateTime(selectedDate.year, selectedDate.month, 1, 0, 0, 0);
        end = DateTime(
          selectedDate.year,
          selectedDate.month + 1,
          1,
        ).subtract(const Duration(seconds: 1));
      }

      // Ringkasan keuangan periode
      final revenue = await txRepo.getTotalIncomeByDateRange(start, end);
      final gross = await txRepo.getTotalProfitByDateRange(start, end);
      final cogs = revenue - gross;
      final opCost = await opRepo.getTotalByDateRange(start, end);
      final net = gross - opCost;

      // List pengeluaran operasional
      final opCostsList = await opRepo.getByDateRange(start, end);

      // Agregasi produk terjual
      final transactionsList = await txRepo.getByDateRange(start, end);
      final Map<String, ({String name, int quantity, int totalAmount})>
      soldMap = {};
      for (final tx in transactionsList) {
        for (final item in tx.items) {
          final existing = soldMap[item.productId];
          if (existing != null) {
            soldMap[item.productId] = (
              name: item.productName,
              quantity: existing.quantity + item.quantity,
              totalAmount: existing.totalAmount + item.subtotal,
            );
          } else {
            soldMap[item.productId] = (
              name: item.productName,
              quantity: item.quantity,
              totalAmount: item.subtotal,
            );
          }
        }
      }
      final soldProductsList = soldMap.values.toList()
        ..sort((a, b) => b.quantity.compareTo(a.quantity));

      // Data grafik berdasarkan skala yang dipilih
      final chartData = await _buildChartData(currentState.chartScale);

      // Total kasbon yang dibuat dalam periode aktif (bukan semua outstanding)
      final totalReceivables = await receivableRepo.getTotalByDateRange(
        start,
        end,
      );

      // Total nilai persediaan: Σ (harga beli × stok)
      final products = await productRepo.getAll();
      final totalInventoryValue = products.fold<int>(
        0,
        (sum, p) => sum + (p.purchasePrice * p.stock),
      );

      return currentState.copyWith(
        totalRevenue: revenue,
        totalCOGS: cogs,
        totalOperationalCost: opCost,
        grossProfit: gross,
        netProfit: net,
        operationalCosts: opCostsList,
        chartData: chartData,
        soldProducts: soldProductsList,
        transactions: transactionsList,
        totalReceivables: totalReceivables,
        totalInventoryValue: totalInventoryValue,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      return currentState.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setPeriod(RecapPeriod period) async {
    state = AsyncData(
      state.value!.copyWith(
        period: period,
        // Hapus selectedEndDate saat pindah dari mode Mingguan
        selectedEndDate: null,
        isLoading: true,
      ),
    );
    state = AsyncData(await _loadData(state.value!));
  }

  void changeDate(DateTime date) async {
    state = AsyncData(
      state.value!.copyWith(selectedDate: date, isLoading: true),
    );
    state = AsyncData(await _loadData(state.value!));
  }

  /// Ubah rentang tanggal (digunakan untuk mode Mingguan dengan date range picker).
  void changeDateRange(DateTime start, DateTime end) async {
    state = AsyncData(
      state.value!.copyWith(
        selectedDate: start,
        selectedEndDate: end,
        isLoading: true,
      ),
    );
    state = AsyncData(await _loadData(state.value!));
  }

  /// Ganti skala grafik tanpa me-reload keseluruhan data keuangan.
  Future<void> setChartScale(ChartScale scale) async {
    final current = state.value!;
    state = AsyncData(current.copyWith(chartScale: scale));
    final chartData = await _buildChartData(scale);
    state = AsyncData(state.value!.copyWith(chartData: chartData));
  }

  /// Refresh data keuangan periode aktif tanpa mereset pilihan tanggal/periode.
  Future<void> refresh() async {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(isLoading: true));
      state = AsyncData(await _loadData(current));
    }
  }

  Future<bool> addOperationalCost({
    required String description,
    required int amount,
    required DateTime date,
  }) async {
    state = AsyncData(state.value!.copyWith(isLoading: true));
    try {
      final opRepo = ref.read(operationalCostRepositoryProvider);

      final cost = OperationalCostModel(
        id: '',
        description: description,
        amount: amount,
        date: date,
        createdAt: DateTime.now(),
      );

      await opRepo.insert(cost);
      ref.invalidate(dashboardProvider);
      state = AsyncData(await _loadData(state.value!));
      return true;
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(isLoading: false, errorMessage: e.toString()),
      );
      return false;
    }
  }

  Future<bool> updateOperationalCost(OperationalCostModel cost) async {
    state = AsyncData(state.value!.copyWith(isLoading: true));
    try {
      final opRepo = ref.read(operationalCostRepositoryProvider);
      await opRepo.update(cost);
      ref.invalidate(dashboardProvider);
      state = AsyncData(await _loadData(state.value!));
      return true;
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(isLoading: false, errorMessage: e.toString()),
      );
      return false;
    }
  }

  Future<bool> deleteOperationalCost(String id) async {
    state = AsyncData(state.value!.copyWith(isLoading: true));
    try {
      final opRepo = ref.read(operationalCostRepositoryProvider);
      await opRepo.delete(id);
      ref.invalidate(dashboardProvider);
      state = AsyncData(await _loadData(state.value!));
      return true;
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(isLoading: false, errorMessage: e.toString()),
      );
      return false;
    }
  }
}

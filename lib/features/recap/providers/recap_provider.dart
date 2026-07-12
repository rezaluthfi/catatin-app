import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../data/models/operational_cost_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import 'recap_state.dart';

final recapProvider =
    AsyncNotifierProvider<RecapNotifier, RecapState>(
  RecapNotifier.new,
);

class RecapNotifier extends AsyncNotifier<RecapState> {
  @override
  FutureOr<RecapState> build() async {
    return _loadData(RecapState(selectedDate: DateTime.now()));
  }

  String _getMonthName(int month) {
    return const [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ][month];
  }

  Future<RecapState> _loadData(RecapState currentState) async {
    final txRepo = ref.read(transactionRepositoryProvider);
    final opRepo = ref.read(operationalCostRepositoryProvider);

    try {
      final selectedDate = currentState.selectedDate;
      DateTime start;
      DateTime end;

      if (currentState.period == RecapPeriod.daily) {
        start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 0, 0, 0);
        end = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
      } else if (currentState.period == RecapPeriod.weekly) {
        final weekday = selectedDate.weekday;
        final startOfWeek = DateTime(selectedDate.year, selectedDate.month, selectedDate.day - (weekday - 1), 0, 0, 0);
        start = startOfWeek;
        end = startOfWeek.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
      } else {
        // Monthly
        start = DateTime(selectedDate.year, selectedDate.month, 1, 0, 0, 0);
        end = DateTime(selectedDate.year, selectedDate.month + 1, 1).subtract(const Duration(seconds: 1));
      }

      // Ambil data untuk total ringkasan
      final revenue = await txRepo.getTotalIncomeByDateRange(start, end);
      final gross = await txRepo.getTotalProfitByDateRange(start, end);
      final cogs = revenue - gross;
      final opCost = await opRepo.getTotalByDateRange(start, end);
      final net = gross - opCost;

      // Ambil list pengeluaran operasional
      final opCostsList = await opRepo.getByDateRange(start, end);

      // Agregasi produk terjual
      final transactionsList = await txRepo.getByDateRange(start, end);
      final Map<String, ({String name, int quantity, int totalAmount})> soldMap = {};
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

      // Generate 6 bulan terakhir untuk tren grafik bulanan
      final Map<String, ({int revenue, int netProfit})> chartData = {};
      if (currentState.period == RecapPeriod.monthly) {
        for (int i = 5; i >= 0; i--) {
          final monthDate = DateTime(selectedDate.year, selectedDate.month - i, 1);
          final startOfMonth = DateTime(monthDate.year, monthDate.month, 1);
          final endOfMonth = DateTime(monthDate.year, monthDate.month + 1, 1).subtract(const Duration(seconds: 1));
          
          final r = await txRepo.getTotalIncomeByDateRange(startOfMonth, endOfMonth);
          final g = await txRepo.getTotalProfitByDateRange(startOfMonth, endOfMonth);
          final o = await opRepo.getTotalByDateRange(startOfMonth, endOfMonth);
          final n = g - o;

          final label = _getMonthName(monthDate.month).substring(0, 3);
          chartData[label] = (revenue: r, netProfit: n);
        }
      }

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
    state = AsyncData(state.value!.copyWith(period: period, isLoading: true));
    state = AsyncData(await _loadData(state.value!));
  }

  void changeDate(DateTime date) async {
    state = AsyncData(state.value!.copyWith(selectedDate: date, isLoading: true));
    state = AsyncData(await _loadData(state.value!));
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
      state = AsyncData(state.value!.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
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
      state = AsyncData(state.value!.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
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
      state = AsyncData(state.value!.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }
}

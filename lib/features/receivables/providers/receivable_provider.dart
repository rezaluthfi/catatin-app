import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../data/models/receivable_model.dart';
import 'receivable_state.dart';

final receivableProvider =
    AsyncNotifierProvider<ReceivableNotifier, ReceivableState>(
  ReceivableNotifier.new,
);

class ReceivableNotifier extends AsyncNotifier<ReceivableState> {
  @override
  FutureOr<ReceivableState> build() async {
    return _loadData(const ReceivableState());
  }

  Future<ReceivableState> _loadData(ReceivableState currentState) async {
    final repo = ref.read(receivableRepositoryProvider);
    try {
      final receivables = await repo.getAll();
      return currentState.copyWith(
        receivables: receivables,
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

  void setFilter(ReceivableFilter filter) {
    state = AsyncData(state.value!.copyWith(filter: filter));
  }

  void setSearchQuery(String query) {
    state = AsyncData(state.value!.copyWith(searchQuery: query));
  }

  /// Tambah Piutang Manual (misal kasbon tanpa transaksi POS)
  Future<bool> addManualReceivable({
    required String customerName,
    required int amount,
    DateTime? dueDate,
    String? notes,
  }) async {
    state = AsyncData(state.value!.copyWith(isLoading: true, errorMessage: null));
    try {
      final repo = ref.read(receivableRepositoryProvider);
      
      final now = DateTime.now();
      final receivable = ReceivableModel(
        id: '', // Diisi di repository nanti
        customerName: customerName,
        amount: amount,
        paidAmount: 0,
        status: ReceivableStatus.unpaid,
        dueDate: dueDate,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );
      
      await repo.insert(receivable);
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

  /// Bayar Cicilan
  Future<bool> addPayment(String id, int amount) async {
    state = AsyncData(state.value!.copyWith(isLoading: true, errorMessage: null));
    try {
      final repo = ref.read(receivableRepositoryProvider);
      await repo.addPartialPayment(id, amount);
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

  /// Bayar Lunas
  Future<bool> markAsPaid(String id) async {
    state = AsyncData(state.value!.copyWith(isLoading: true, errorMessage: null));
    try {
      final repo = ref.read(receivableRepositoryProvider);
      await repo.markAsPaid(id);
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

  /// Hapus Kasbon
  Future<bool> deleteReceivable(String id) async {
    state = AsyncData(state.value!.copyWith(isLoading: true, errorMessage: null));
    try {
      final repo = ref.read(receivableRepositoryProvider);
      await repo.delete(id);
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

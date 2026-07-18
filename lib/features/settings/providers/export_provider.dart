/// Provider untuk fitur Export Laporan (PDF & XLSX).
///
/// Mengambil data dari semua repository berdasarkan rentang tanggal,
/// lalu menghasilkan file via [ExportService] dan membagikannya via share_plus.
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../core/providers/repository_providers.dart';
import '../../../core/services/export_data.dart';
import '../../../core/services/export_service.dart';
import 'settings_provider.dart';

/// Enum format ekspor.
enum ExportFormat { pdf, xlsx }

/// State sederhana untuk loading/error di ExportSheet.
class ExportState {
  const ExportState({
    this.isLoading = false,
    this.error,
    this.lastExportedFile,
  });

  final bool isLoading;
  final String? error;
  final File? lastExportedFile;

  ExportState copyWith({
    bool? isLoading,
    String? error,
    File? lastExportedFile,
  }) {
    return ExportState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastExportedFile: lastExportedFile ?? this.lastExportedFile,
    );
  }
}

final exportProvider = AsyncNotifierProvider<ExportNotifier, ExportState>(
  ExportNotifier.new,
);

class ExportNotifier extends AsyncNotifier<ExportState> {
  @override
  Future<ExportState> build() async => const ExportState();

  /// Kumpulkan data dan generate file laporan.
  Future<File?> generateReport({
    required DateTime startDate,
    required DateTime endDate,
    required ExportFormat format,
  }) async {
    state = const AsyncLoading();

    try {
      // Normalise dates: start = 00:00:00, end = 23:59:59
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      final txRepo = ref.read(transactionRepositoryProvider);
      final costRepo = ref.read(operationalCostRepositoryProvider);
      final receivableRepo = ref.read(receivableRepositoryProvider);
      final productRepo = ref.read(productRepositoryProvider);
      final settingsState = await ref.read(settingsProvider.future);

      // Ambil semua data secara paralel
      final txFuture = txRepo.getByDateRange(start, end);
      final costFuture = costRepo.getByDateRange(start, end);
      final receivableFuture = receivableRepo.getAll();
      final productFuture = productRepo.getAll();

      final transactions = await txFuture;
      final operationalCosts = await costFuture;
      final receivables = await receivableFuture;
      final products = await productFuture;

      // Load histories untuk tiap produk secara paralel
      final historyFutures = products.map((p) => productRepo.getStockHistory(p.id));
      final historiesLists = await Future.wait(historyFutures);
      final allHistories = historiesLists.expand((h) => h).toList();

      final exportData = ExportData(
        businessName: settingsState.businessName,
        ownerName: settingsState.ownerName,
        startDate: start,
        endDate: end,
        transactions: transactions,
        operationalCosts: operationalCosts,
        receivables: receivables,
        products: products,
        stockHistory: allHistories,
      );

      final File file;
      if (format == ExportFormat.pdf) {
        file = await ExportService.generatePdf(exportData);
      } else {
        file = await ExportService.generateXlsx(exportData);
      }

      state = AsyncData(ExportState(lastExportedFile: file));
      return file;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

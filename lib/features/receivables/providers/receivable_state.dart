import '../../../data/models/receivable_model.dart';

enum ReceivableFilter {
  all('Semua'),
  unpaid('Belum Lunas'),
  paid('Lunas');

  const ReceivableFilter(this.label);
  final String label;
}

class ReceivableState {
  const ReceivableState({
    this.receivables = const [],
    this.filter = ReceivableFilter.unpaid,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  final List<ReceivableModel> receivables;
  final ReceivableFilter filter;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  ReceivableState copyWith({
    List<ReceivableModel>? receivables,
    ReceivableFilter? filter,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ReceivableState(
      receivables: receivables ?? this.receivables,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Piutang yang difilter dan dicari.
  List<ReceivableModel> get filteredReceivables {
    var filtered = receivables;

    // Filter berdasarkan status
    if (filter == ReceivableFilter.unpaid) {
      filtered = filtered
          .where((r) =>
              r.status == ReceivableStatus.unpaid ||
              r.status == ReceivableStatus.partial)
          .toList();
    } else if (filter == ReceivableFilter.paid) {
      filtered =
          filtered.where((r) => r.status == ReceivableStatus.paid).toList();
    }

    // Filter berdasarkan pencarian nama pelanggan
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered
          .where((r) => r.customerName.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/router.dart';
import '../../../core/extensions/currency_extension.dart';
import '../../../data/models/receivable_model.dart';
import '../providers/receivable_provider.dart';
import '../providers/receivable_state.dart';
import '../widgets/receivable_payment_sheet.dart';

class ReceivablesListScreen extends ConsumerStatefulWidget {
  const ReceivablesListScreen({super.key});

  @override
  ConsumerState<ReceivablesListScreen> createState() => _ReceivablesListScreenState();
}

class _ReceivablesListScreenState extends ConsumerState<ReceivablesListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getMonthName(int month) {
    return const [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ][month];
  }

  void _showPaymentSheet(ReceivableModel receivable) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReceivablePaymentSheet(receivable: receivable),
    );
  }

  void _showPaidOptionsDialog(ReceivableModel item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ubah Status Piutang'),
        content: Text(
          'Piutang atas nama "${item.customerName}" sudah lunas. Apakah Anda ingin mengembalikan status piutang ini menjadi Belum Lunas (reset pembayaran)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await ref
                  .read(receivableProvider.notifier)
                  .resetPayment(item.id);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pembayaran berhasil di-reset menjadi Belum Lunas'),
                    backgroundColor: AppColors.income,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal mereset pembayaran'),
                    backgroundColor: AppColors.expense,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Reset Pembayaran'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(ReceivableModel receivable) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Piutang'),
        content: Text(
          'Apakah Anda yakin ingin menghapus piutang atas nama ${receivable.customerName} sebesar ${receivable.amount.toRupiah()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref
          .read(receivableProvider.notifier)
          .deleteReceivable(receivable.id);

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Piutang berhasil dihapus'),
            backgroundColor: AppColors.income,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus piutang'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(receivableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Piutang Pelanggan'),
      ),
      body: stateAsync.when(
        data: (state) {
          final totalOutstanding = state.receivables
              .where((r) => r.status != ReceivableStatus.paid)
              .fold<int>(0, (sum, r) => sum + r.remainingAmount);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ringkasan Total Piutang Aktif
              Container(
                margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Piutang Belum Tertagih',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      totalOutstanding.toRupiah(),
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref.read(receivableProvider.notifier).setSearchQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari nama pelanggan...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(receivableProvider.notifier)
                                  .setSearchQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: ReceivableFilter.values.map((filter) {
                    final isSelected = state.filter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(filter.label),
                        onSelected: (_) {
                          ref.read(receivableProvider.notifier).setFilter(filter);
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.primary,
                        labelStyle: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // List Piutang
              Expanded(
                child: state.filteredReceivables.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 64,
                              color: AppColors.textSecondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.searchQuery.isNotEmpty
                                  ? 'Pelanggan tidak ditemukan'
                                  : 'Tidak ada piutang',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        itemCount: state.filteredReceivables.length,
                        itemBuilder: (context, index) {
                          final item = state.filteredReceivables[index];
                          final createdDate = item.createdAt;

                          Color statusColor;
                          String statusLabel;
                          if (item.status == ReceivableStatus.paid) {
                            statusColor = AppColors.income;
                            statusLabel = 'Lunas';
                          } else if (item.status == ReceivableStatus.partial) {
                            statusColor = Colors.orange;
                            statusLabel = 'Dicicil';
                          } else {
                            statusColor = AppColors.expense;
                            statusLabel = 'Belum Bayar';
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            child: InkWell(
                              onTap: item.isPaid ? null : () => _showPaymentSheet(item),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.customerName,
                                                style: AppTextStyles.bodyLarge
                                                    .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Dibuat: ${createdDate.day} ${_getMonthName(createdDate.month)} ${createdDate.year}',
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Status Badge & Action Menu
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: statusColor.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                statusLabel,
                                                style: AppTextStyles.labelSmall
                                                    .copyWith(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            PopupMenuButton<String>(
                                              onSelected: (val) {
                                                if (val == 'delete') {
                                                  _confirmDelete(item);
                                                } else if (val == 'reset') {
                                                  _showPaidOptionsDialog(item);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                if (item.paidAmount > 0)
                                                  const PopupMenuItem(
                                                    value: 'reset',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.restart_alt_outlined,
                                                          color: AppColors.primary,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text('Reset Pembayaran'),
                                                      ],
                                                    ),
                                                  ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.delete_outline,
                                                        color: AppColors.expense,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text('Hapus'),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total Tagihan',
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.amount.toRupiah(),
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              item.isPaid
                                                  ? 'Sudah Dibayar'
                                                  : 'Sisa Utang',
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.isPaid
                                                  ? item.amount.toRupiah()
                                                  : item.remainingAmount
                                                      .toRupiah(),
                                              style: AppTextStyles.bodyLarge
                                                  .copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: item.isPaid
                                                    ? AppColors.income
                                                    : AppColors.expense,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Terjadi kesalahan: $err'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null, // Mencegah crash hero animation
        onPressed: () => context.push(AppRoutes.receivableAdd),
        child: const Icon(Icons.add),
      ),
    );
  }
}

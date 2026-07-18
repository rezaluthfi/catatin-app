import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/extensions/currency_extension.dart';
import '../../../data/models/operational_cost_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_enums.dart';
import '../../../core/utils/transaction_notes_parser.dart';
import '../providers/recap_provider.dart';
import '../providers/recap_state.dart';
import '../widgets/add_expense_sheet.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/app_footer.dart';

class RecapScreen extends ConsumerStatefulWidget {
  const RecapScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends ConsumerState<RecapScreen> {
  late int _selectedTab;

  static const int _pageSize = 10;
  bool _showAllTransactions = false;
  bool _showAllExpenses = false;
  bool _showAllSoldProducts = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant RecapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      _selectedTab = widget.initialTab;
    }
  }

  Widget _buildTabChip(int index, String label) {
    final isSelected = _selectedTab == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: true,
      checkmarkColor: AppColors.primary,
      onSelected: (val) {
        if (val) {
          setState(() => _selectedTab = index);
        }
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.1),
      labelStyle: AppTextStyles.bodyMedium.copyWith(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
    );
  }

  void _showTransactionDetailSheet(BuildContext context, TransactionModel tx) {
    final hourStr = tx.createdAt.hour.toString().padLeft(2, '0');
    final minStr = tx.createdAt.minute.toString().padLeft(2, '0');
    final formattedTime =
        '${tx.createdAt.day} ${_getMonthName(tx.createdAt.month)} ${tx.createdAt.year} pukul $hourStr:$minStr';

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Detail Transaksi', style: AppTextStyles.headlineSmall),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Waktu',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            formattedTime,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Metode Pembayaran',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (tx.paymentMethod == PaymentMethod.credit
                                      ? AppColors.secondary
                                      : (tx.paymentMethod == PaymentMethod.nonCash
                                          ? AppColors.primary
                                          : AppColors.income))
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tx.paymentMethod == PaymentMethod.credit
                                  ? 'Kasbon'
                                  : (tx.paymentMethod == PaymentMethod.nonCash
                                      ? 'Non Tunai'
                                      : 'Tunai'),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: tx.paymentMethod == PaymentMethod.credit
                                    ? AppColors.secondary
                                    : (tx.paymentMethod == PaymentMethod.nonCash
                                        ? AppColors.primary
                                        : AppColors.income),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        'Daftar Produk',
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...tx.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName.isNotEmpty
                                          ? item.productName
                                          : '(Produk telah dihapus)',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: item.productName.isEmpty
                                            ? AppColors.textSecondary
                                            : null,
                                        fontStyle: item.productName.isEmpty
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                      ),
                                    ),
                                    Text(
                                      '${item.quantity} x ${item.sellingPriceAtTime.toRupiah()}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                item.subtotal.toRupiah(),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Pembayaran',
                            style: AppTextStyles.headlineMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            tx.totalAmount.toRupiah(),
                            style: AppTextStyles.headlineLarge.copyWith(
                              color: tx.paymentMethod == PaymentMethod.credit
                                  ? AppColors.secondary
                                  : (tx.paymentMethod == PaymentMethod.nonCash
                                      ? AppColors.primary
                                      : AppColors.income),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      () {
                        final paymentDetail =
                            TransactionNotesParser.getPaymentDetail(tx.notes);
                        final customNotes =
                            TransactionNotesParser.getCustomNotes(tx.notes);

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (paymentDetail != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Detail Rekening Penerima:',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      paymentDetail,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (customNotes != null && customNotes.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Catatan:',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      customNotes,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      }(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    return const [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ][month];
  }

  void _showAddExpense(BuildContext context, {OperationalCostModel? expense}) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddExpenseSheet(expense: expense),
    );
  }

  Future<void> _confirmDeleteExpense(
    BuildContext context,
    WidgetRef ref,
    OperationalCostModel expense,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengeluaran'),
        content: Text(
          'Apakah Anda yakin ingin menghapus catatan pengeluaran "${expense.description}" sebesar ${expense.amount.toRupiah()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref
          .read(recapProvider.notifier)
          .deleteOperationalCost(expense.id);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengeluaran berhasil dihapus'),
              backgroundColor: AppColors.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menghapus pengeluaran'),
              backgroundColor: AppColors.expense,
            ),
          );
        }
      }
    }
  }

  String _formatValueShort(double value) {
    final absVal = value.abs();
    final sign = value < 0 ? '-' : '';
    if (absVal >= 1000000) {
      return '$sign${(absVal / 1000000).toStringAsFixed(1).replaceAll('.0', '')}jt';
    } else if (absVal >= 1000) {
      return '$sign${(absVal / 1000).toStringAsFixed(0)}rb';
    }
    return '$sign${absVal.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(recapProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rekapitulasi Keuangan'),
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: stateAsync.when(
        data: (state) {
          final isProfit = state.netProfit > 0;
          final formattedPeriod = _getFormattedPeriodText(state);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Period & Date Picker Bar
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    // Segmented Button untuk Pilih Periode
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SegmentedButton<RecapPeriod>(
                        segments: const [
                          ButtonSegment(
                            value: RecapPeriod.daily,
                            label: Text('Harian'),
                          ),
                          ButtonSegment(
                            value: RecapPeriod.weekly,
                            label: Text('Mingguan'),
                          ),
                          ButtonSegment(
                            value: RecapPeriod.monthly,
                            label: Text('Bulanan'),
                          ),
                        ],
                        showSelectedIcon: false,
                        selected: {state.period},
                        onSelectionChanged: (newSelection) {
                          ref
                              .read(recapProvider.notifier)
                              .setPeriod(newSelection.first);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date Navigator
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 64, // Fixed height untuk konsistensi antar tab
                        child: state.period == RecapPeriod.weekly
                            ? _buildWeeklyDateRange(context, state, ref)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: () {
                                      ref
                                          .read(recapProvider.notifier)
                                          .changeDate(_adjustDate(state, -1));
                                    },
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () async {
                                        if (state.period == RecapPeriod.daily) {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: state.selectedDate,
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime.now().add(
                                              const Duration(days: 365),
                                            ),
                                            helpText: 'Pilih Tanggal',
                                            confirmText: 'Pilih',
                                            cancelText: 'Batal',
                                          );
                                          if (picked != null && context.mounted) {
                                            ref
                                                .read(recapProvider.notifier)
                                                .changeDate(picked);
                                          }
                                        } else {
                                          // Bulanan: pilih bulan
                                          final picked = await _showMonthPicker(
                                            context,
                                            state.selectedDate,
                                          );
                                          if (picked != null && context.mounted) {
                                            ref
                                                .read(recapProvider.notifier)
                                                .changeDate(picked);
                                          }
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 4,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              formattedPeriod,
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  AppTextStyles.bodyLarge.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.calendar_month_outlined,
                                              size: 16,
                                              color: AppColors.textSecondary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: () {
                                      ref
                                          .read(recapProvider.notifier)
                                          .changeDate(_adjustDate(state, 1));
                                    },
                                  ),
                                ],
                              ),
                      ),
                    ),

                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Ringkasan Utama Keuntungan Bersih
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Laba Bersih',
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                state.netProfit.toRupiah(),
                                style: AppTextStyles.headlineLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isProfit
                                      ? AppColors.income
                                      : AppColors.expense,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Divider(height: 1),
                              const SizedBox(height: 16),
                              _buildRowDetail(
                                'Pemasukan Kotor (Omzet)',
                                state.totalRevenue.toRupiah(),
                                valueColor: AppColors.income,
                              ),
                              const SizedBox(height: 8),
                              _buildRowDetail(
                                'Harga Pokok Penjualan (HPP)',
                                '- ${state.totalCOGS.toRupiah()}',
                              ),
                              const SizedBox(height: 8),
                              _buildRowDetail(
                                'Biaya Operasional',
                                '- ${state.totalOperationalCost.toRupiah()}',
                                valueColor: AppColors.expense,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Card Arus Kas (hanya Bulanan)
                      if (state.period == RecapPeriod.monthly) ...[
                        const SizedBox(height: 16),
                        _buildOperatingCashFlowCard(state),
                      ],

                      // Section Chart Tren Keuangan
                      const SizedBox(height: 24),
                      _buildChartSection(state),

                      // Tab Selector Section
                      const SizedBox(height: 24),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildTabChip(
                              0,
                              'Transaksi (${state.transactions.length})',
                            ),
                            const SizedBox(width: 8),
                            _buildTabChip(
                              1,
                              'Pengeluaran (${state.operationalCosts.length})',
                            ),
                            const SizedBox(width: 8),
                            _buildTabChip(
                              2,
                              'Produk Terjual (${state.soldProducts.length})',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tab Contents
                      if (_selectedTab == 0) ...[
                        // Section Riwayat Transaksi
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Riwayat Transaksi',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (state.transactions.isEmpty)
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_rounded,
                                    size: 48,
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Belum ada transaksi dalam periode ini',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          () {
                            final txList = state.transactions;
                            final displayList = _showAllTransactions
                                ? txList
                                : txList.take(_pageSize).toList();
                            return Column(
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: displayList.length,
                                  itemBuilder: (context, index) {
                                    final tx = displayList[index];
                                    final hourStr = tx.createdAt.hour
                                        .toString()
                                        .padLeft(2, '0');
                                    final minStr = tx.createdAt.minute
                                        .toString()
                                        .padLeft(2, '0');
                                    final formattedTime =
                                        '${tx.createdAt.day} ${_getMonthName(tx.createdAt.month)} ${tx.createdAt.year} - $hourStr:$minStr';

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: ListTile(
                                        onTap: () =>
                                            _showTransactionDetailSheet(
                                              context,
                                              tx,
                                            ),
                                        leading: () {
                                          final txColor = tx.paymentMethod == PaymentMethod.credit
                                              ? AppColors.secondary
                                              : (tx.paymentMethod == PaymentMethod.nonCash
                                                  ? AppColors.primary
                                                  : AppColors.income);
                                          final txIcon = tx.paymentMethod == PaymentMethod.credit
                                              ? Icons.payments_outlined
                                              : (tx.paymentMethod == PaymentMethod.nonCash
                                                  ? Icons.qr_code_2_rounded
                                                  : Icons.shopping_bag_outlined);
                                          return Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: txColor.withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              txIcon,
                                              color: txColor,
                                              size: 18,
                                            ),
                                          );
                                        }(),
                                        title: Text(
                                          tx.paymentMethod == PaymentMethod.credit
                                              ? 'Kasbon'
                                              : (tx.paymentMethod == PaymentMethod.nonCash
                                                  ? 'Non Tunai'
                                                  : 'Tunai'),
                                          style: AppTextStyles.bodyLarge
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              formattedTime,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                            () {
                                              final paymentDetail =
                                                  TransactionNotesParser
                                                      .getPaymentDetail(
                                                          tx.notes);
                                              final customNotes =
                                                  TransactionNotesParser
                                                      .getCustomNotes(tx.notes);
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (paymentDetail != null) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      paymentDetail,
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style: AppTextStyles
                                                          .bodySmall
                                                          .copyWith(
                                                        color: AppColors.primary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                  if (customNotes != null &&
                                                      customNotes.isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      customNotes,
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style: AppTextStyles
                                                          .bodySmall
                                                          .copyWith(
                                                        color: AppColors
                                                            .textSecondary,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              );
                                            }(),
                                          ],
                                        ),
                                        trailing: Text(
                                          tx.totalAmount.toRupiah(),
                                          style: AppTextStyles.bodyLarge
                                              .copyWith(
                                                color: tx.paymentMethod == PaymentMethod.credit
                                                    ? AppColors.secondary
                                                    : (tx.paymentMethod == PaymentMethod.nonCash
                                                        ? AppColors.primary
                                                        : AppColors.income),
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (txList.length > _pageSize &&
                                    !_showAllTransactions)
                                  TextButton.icon(
                                    onPressed: () => setState(
                                      () => _showAllTransactions = true,
                                    ),
                                    icon: const Icon(Icons.expand_more_rounded),
                                    label: Text(
                                      'Tampilkan ${txList.length - _pageSize} transaksi lainnya',
                                    ),
                                  ),
                              ],
                            );
                          }(),
                        ],
                      ] else if (_selectedTab == 1) ...[
                        // Section Biaya Operasional / Pengeluaran
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Catatan Pengeluaran',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _showAddExpense(context),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Tambah'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (state.operationalCosts.isEmpty)
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.money_off_rounded,
                                    size: 48,
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tidak ada pengeluaran operasional',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          () {
                            final costList = state.operationalCosts;
                            final displayList = _showAllExpenses
                                ? costList
                                : costList.take(_pageSize).toList();
                            return Column(
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: displayList.length,
                                  itemBuilder: (context, index) {
                                    final item = displayList[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: InkWell(
                                        onTap: () => _showAddExpense(
                                          context,
                                          expense: item,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.expense
                                                      .withValues(alpha: 0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.arrow_outward_rounded,
                                                  color: AppColors.expense,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.description,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: AppTextStyles
                                                          .bodyLarge
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${item.date.day} ${_getMonthName(item.date.month)} ${item.date.year}',
                                                      style: AppTextStyles
                                                          .bodySmall
                                                          .copyWith(
                                                            color: AppColors
                                                                .textSecondary,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '- ${item.amount.toRupiah()}',
                                                    style: AppTextStyles
                                                        .bodyLarge
                                                        .copyWith(
                                                          color:
                                                              AppColors.expense,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  PopupMenuButton<String>(
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                    icon: const Icon(
                                                      Icons.more_vert,
                                                      color: AppColors
                                                          .textSecondary,
                                                      size: 20,
                                                    ),
                                                    onSelected: (value) {
                                                      if (value == 'edit') {
                                                        _showAddExpense(
                                                          context,
                                                          expense: item,
                                                        );
                                                      } else if (value ==
                                                          'delete') {
                                                        _confirmDeleteExpense(
                                                          context,
                                                          ref,
                                                          item,
                                                        );
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      PopupMenuItem(
                                                        value: 'edit',
                                                        child: Row(
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .edit_outlined,
                                                              size: 20,
                                                              color: AppColors
                                                                  .textPrimary,
                                                            ),
                                                            const SizedBox(
                                                              width: 12,
                                                            ),
                                                            Text(
                                                              'Edit',
                                                              style: AppTextStyles
                                                                  .bodyMedium,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'delete',
                                                        child: Row(
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .delete_outline,
                                                              color: AppColors
                                                                  .expense,
                                                              size: 20,
                                                            ),
                                                            const SizedBox(
                                                              width: 12,
                                                            ),
                                                            Text(
                                                              'Hapus',
                                                              style: AppTextStyles
                                                                  .bodyMedium
                                                                  .copyWith(
                                                                    color: AppColors
                                                                        .expense,
                                                                  ),
                                                            ),
                                                          ],
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
                                if (costList.length > _pageSize &&
                                    !_showAllExpenses)
                                  TextButton.icon(
                                    onPressed: () =>
                                        setState(() => _showAllExpenses = true),
                                    icon: const Icon(Icons.expand_more_rounded),
                                    label: Text(
                                      'Tampilkan ${costList.length - _pageSize} pengeluaran lainnya',
                                    ),
                                  ),
                              ],
                            );
                          }(),
                        ],
                      ] else ...[
                        // Section Produk Terjual
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Produk Terjual',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (state.soldProducts.isEmpty)
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 48,
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Belum ada produk terjual',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          () {
                            final productList = state.soldProducts;
                            final displayList = _showAllSoldProducts
                                ? productList
                                : productList.take(_pageSize).toList();
                            return Column(
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: displayList.length,
                                  itemBuilder: (context, index) {
                                    final item = displayList[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.1,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.shopping_bag_rounded,
                                            color: AppColors.primary,
                                            size: 18,
                                          ),
                                        ),
                                        title: Text(
                                          item.name,
                                          style: AppTextStyles.bodyLarge
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        subtitle: Text(
                                          'Terjual: ${item.quantity} pcs',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                        trailing: Text(
                                          item.totalAmount.toRupiah(),
                                          style: AppTextStyles.bodyLarge
                                              .copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (productList.length > _pageSize &&
                                    !_showAllSoldProducts)
                                  TextButton.icon(
                                    onPressed: () => setState(
                                      () => _showAllSoldProducts = true,
                                    ),
                                    icon: const Icon(Icons.expand_more_rounded),
                                    label: Text(
                                      'Tampilkan ${productList.length - _pageSize} produk lainnya',
                                    ),
                                  ),
                              ],
                            );
                          }(),
                        ],
                      ],
                      const AppFooter(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => ShimmerLoading(type: ShimmerType.recap),
        error: (err, stack) => Center(child: Text('Terjadi kesalahan: $err')),
      ),
    );
  }

  /// Date navigator khusus mode Mingguan: dua DatePicker (Mulai & Selesai)
  /// masing-masing identik dengan gaya harian (showDatePicker biasa).
  Widget _buildWeeklyDateRange(
    BuildContext context,
    RecapState state,
    WidgetRef ref,
  ) {
    final startDate = state.selectedDate;
    final endDate =
        state.selectedEndDate ?? state.selectedDate.add(const Duration(days: 6));

    Widget dateField({
      required String label,
      required DateTime date,
      required bool isStart,
    }) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: isStart ? DateTime(2020) : startDate,
                  lastDate: isStart
                      ? endDate
                      : DateTime.now().add(const Duration(days: 365)),
                  helpText: isStart
                      ? 'Pilih Tanggal Mulai'
                      : 'Pilih Tanggal Selesai',
                  confirmText: 'Pilih',
                  cancelText: 'Batal',
                );
                if (picked != null && context.mounted) {
                  ref.read(recapProvider.notifier).changeDateRange(
                        isStart ? picked : startDate,
                        isStart ? endDate : picked,
                      );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${date.day} ${_getMonthName(date.month).substring(0, 3)} ${date.year}',
                          textAlign: TextAlign.center,
                          softWrap: false,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Panah kiri — geser -7 hari
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            ref.read(recapProvider.notifier).changeDateRange(
                  startDate.subtract(const Duration(days: 7)),
                  endDate.subtract(const Duration(days: 7)),
                );
          },
        ),
        // Start date field
        dateField(label: 'Mulai', date: startDate, isStart: true),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('–'),
        ),
        // End date field
        dateField(label: 'Selesai', date: endDate, isStart: false),
        // Panah kanan — geser +7 hari
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            ref.read(recapProvider.notifier).changeDateRange(
                  startDate.add(const Duration(days: 7)),
                  endDate.add(const Duration(days: 7)),
                );
          },
        ),
      ],
    );
  }

  Widget _buildRowDetail(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Card Arus Kas dari Aktivitas Operasional (hanya mode Bulanan).
  Widget _buildOperatingCashFlowCard(RecapState state) {
    final kasFromOps =
        state.netProfit - state.totalReceivables - state.totalInventoryValue;
    final isPositive = kasFromOps >= 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kas dari Aktivitas Operasional',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildCashFlowRow(
              'Laba Bersih',
              state.netProfit,
              isDeduction: false,
            ),
            const SizedBox(height: 8),
            _buildCashFlowRow(
              'Kurang akun piutang',
              state.totalReceivables,
              isDeduction: true,
            ),
            const SizedBox(height: 8),
            _buildCashFlowRow(
              'Kurang persediaan barang',
              state.totalInventoryValue,
              isDeduction: true,
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Kas Bersih dari Aktivitas Operasional',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isPositive ? kasFromOps.toRupiah() : (-kasFromOps).toRupiah(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPositive ? AppColors.income : AppColors.expense,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashFlowRow(
    String label,
    int amount, {
    required bool isDeduction,
  }) {
    final displayText = isDeduction
        ? '(${amount.toRupiah()})'
        : amount.toRupiah();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          displayText,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDeduction ? AppColors.expense : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(RecapState state) {
    final entries = state.chartData.entries.toList();
    final keys = state.chartData.keys.toList();

    // Temukan nilai minimum dan maksimum untuk penskalaan grafik Y
    double minVal = double.infinity;
    double maxVal = -double.infinity;
    for (final entry in entries) {
      final rev = entry.value.revenue.toDouble();
      final net = entry.value.netProfit.toDouble();
      if (rev < minVal) minVal = rev;
      if (net < minVal) minVal = net;
      if (rev > maxVal) maxVal = rev;
      if (net > maxVal) maxVal = net;
    }

    double minScaleY;
    double maxScaleY;
    if (minVal == double.infinity || maxVal == -double.infinity) {
      minScaleY = 0;
      maxScaleY = 100000.0;
    } else if (minVal == maxVal) {
      minScaleY = minVal > 0 ? minVal * 0.8 : 0;
      maxScaleY = maxVal > 0 ? maxVal * 1.2 : 100000.0;
    } else {
      final diff = maxVal - minVal;
      minScaleY = minVal - (diff * 0.15);
      maxScaleY = maxVal + (diff * 0.15);

      if (minVal >= 0 && minScaleY < 0) {
        minScaleY = 0;
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tren Keuangan',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Selector skala waktu grafik — identik dengan Dashboard
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildScaleChip(state, ChartScale.week7, '7 Hari'),
                  const SizedBox(width: 8),
                  _buildScaleChip(state, ChartScale.month1, '1 Bulan'),
                  const SizedBox(width: 8),
                  _buildScaleChip(state, ChartScale.month3, '3 Bulan'),
                  const SizedBox(width: 8),
                  _buildScaleChip(state, ChartScale.month6, '6 Bulan'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Legenda
            Row(
              children: [
                _buildLegendItem('Omzet', AppColors.income),
                const SizedBox(width: 16),
                _buildLegendItem('Laba Bersih', AppColors.info),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => AppColors.surface,
                      tooltipBorder: const BorderSide(
                        color: AppColors.border,
                        width: 1,
                      ),
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final val = touchedSpot.y.toInt();
                          final isRevenue = touchedSpot.barIndex == 0;
                          final label = isRevenue ? 'Pemasukan' : 'Laba';
                          final formattedVal = val.toRupiah();
                          return LineTooltipItem(
                            '$label: $formattedVal',
                            TextStyle(
                              fontFamily: 'GoogleSans',
                              color: isRevenue
                                  ? AppColors.income
                                  : AppColors.info,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          if (value == minScaleY || value == maxScaleY) {
                            return const SizedBox();
                          }
                          return Text(
                            _formatValueShort(value),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final rounded = value.round();
                          if ((value - rounded).abs() > 0.05) {
                            return const SizedBox.shrink();
                          }
                          final index = rounded;
                          if (index < 0 || index >= keys.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              keys[index],
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: -0.2,
                  maxX: (keys.length - 1).toDouble() + 0.2,
                  minY: minScaleY,
                  maxY: maxScaleY,
                  lineBarsData: [
                    // Line 1: Omzet (Revenue)
                    LineChartBarData(
                      spots: List.generate(entries.length, (i) {
                        return FlSpot(
                          i.toDouble(),
                          entries[i].value.revenue.toDouble(),
                        );
                      }),
                      isCurved: true,
                      color: AppColors.income,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.income.withValues(alpha: 0.15),
                            AppColors.income.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Line 2: Laba Bersih (Net Profit)
                    LineChartBarData(
                      spots: List.generate(entries.length, (i) {
                        return FlSpot(
                          i.toDouble(),
                          entries[i].value.netProfit.toDouble().clamp(
                            minScaleY,
                            maxScaleY,
                          ),
                        );
                      }),
                      isCurved: true,
                      color: AppColors.info,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.info.withValues(alpha: 0.15),
                            AppColors.info.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScaleChip(RecapState state, ChartScale target, String label) {
    final isSelected = state.chartScale == target;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: true,
      checkmarkColor: AppColors.primary,
      onSelected: (val) {
        if (val) {
          ref.read(recapProvider.notifier).setChartScale(target);
        }
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.1),
      labelStyle: AppTextStyles.bodyMedium.copyWith(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _getFormattedPeriodText(RecapState state) {
    final d = state.selectedDate;
    if (state.period == RecapPeriod.daily) {
      return '${d.day} ${_getMonthName(d.month)} ${d.year}';
    } else if (state.period == RecapPeriod.weekly) {
      // Tampilkan rentang yang dipilih user (selectedDate – selectedEndDate)
      final end = state.selectedEndDate ??
          state.selectedDate.add(const Duration(days: 6));
      final startStr =
          '${d.day} ${_getMonthName(d.month).substring(0, 3)}';
      final endStr =
          '${end.day} ${_getMonthName(end.month).substring(0, 3)} ${end.year}';
      return '$startStr – $endStr';
    } else {
      return '${_getMonthName(d.month)} ${d.year}';
    }
  }

  /// Sesuaikan tanggal untuk tombol prev/next (harian dan bulanan).
  /// Untuk mingguan, penanganan dilakukan langsung di UI masing-masing tombol.
  DateTime _adjustDate(RecapState state, int offset) {
    final d = state.selectedDate;
    if (state.period == RecapPeriod.daily) {
      return d.add(Duration(days: offset));
    } else {
      // Bulanan
      return DateTime(d.year, d.month + offset, 1);
    }
  }

  /// Tampilkan dialog pemilih bulan.
  Future<DateTime?> _showMonthPicker(
    BuildContext context,
    DateTime initial,
  ) async {
    int selectedYear = initial.year;

    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    return showDialog<DateTime>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () =>
                      setDialogState(() => selectedYear--),
                ),
                Text(
                  '$selectedYear',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () =>
                      setDialogState(() => selectedYear++),
                ),
              ],
            ),
            contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            content: SizedBox(
              width: 280,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (_, index) {
                  final month = index + 1;
                  final isActive = initial.month == month &&
                      initial.year == selectedYear;
                  return InkWell(
                    onTap: () => Navigator.of(ctx)
                        .pop(DateTime(selectedYear, month, 1)),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        monthNames[index],
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal'),
              ),
            ],
          );
        },
      ),
    );
  }
}

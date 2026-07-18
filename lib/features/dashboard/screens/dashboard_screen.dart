import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/router.dart';
import '../../../core/extensions/currency_extension.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_enums.dart';
import '../../../core/utils/transaction_notes_parser.dart';
import '../../settings/providers/settings_provider.dart';
import '../../recap/widgets/add_expense_sheet.dart';
import '../providers/dashboard_provider.dart';
import '../providers/dashboard_state.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/app_footer.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      return 'Selamat Pagi';
    } else if (hour < 15) {
      return 'Selamat Siang';
    } else if (hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
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
                              color:
                                  (tx.paymentMethod == PaymentMethod.credit
                                          ? AppColors.secondary
                                          : (tx.paymentMethod ==
                                                    PaymentMethod.nonCash
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
                            if (customNotes != null &&
                                customNotes.isNotEmpty) ...[
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(dashboardProvider);
    final settingsState = ref.watch(settingsProvider).valueOrNull;
    final ownerName = settingsState?.ownerName ?? 'Pemilik';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: stateAsync.when(
          data: (state) {
            final isLowStock = state.lowStockProducts.isNotEmpty;
            final businessName = state.businessName;
            final initial = businessName.isNotEmpty
                ? businessName[0].toUpperCase()
                : 'U';

            return RefreshIndicator(
              onRefresh: () => ref.read(dashboardProvider.notifier).reload(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Greeting & Nama Toko
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${_getGreeting()}, ',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    ownerName,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                businessName,
                                style: AppTextStyles.headlineMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Ringkasan Keuangan Hari Ini (Hero Card Solid)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Laba Hari Ini',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.netProfitToday.toRupiah(),
                              style: AppTextStyles.headlineLarge.copyWith(
                                color: state.netProfitToday <= 0
                                    ? const Color(0xFFE65A50)
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                // Pemasukan
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.arrow_downward_rounded,
                                            color: Colors.white70,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Penerimaan',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color: Colors.white70,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        state.incomeToday.toRupiah(),
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 32,
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                                const SizedBox(width: 16),
                                // Pengeluaran
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.arrow_upward_rounded,
                                            color: Colors.white70,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Pengeluaran',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color: Colors.white70,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        state.expenseToday.toRupiah(),
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Alert Stok Menipis
                    if (isLowStock) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.expense.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.expense,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Peringatan Stok Menipis!',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.expense,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ada ${state.lowStockProducts.length} produk yang hampir habis.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.push(AppRoutes.inventory),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.expense,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Lihat',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.expense,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Akses Cepat (Quick Actions Grid 2x2)
                    Text(
                      'Akses Cepat',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionCard(
                            context,
                            title: 'Catat Transaksi',
                            subtitle: 'Transaksi kasir cepat',
                            icon: Icons.add_shopping_cart_rounded,
                            iconColor: AppColors.primary,
                            bgColor: AppColors.primary.withValues(alpha: 0.1),
                            onTap: () => context.push(AppRoutes.pos),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionCard(
                            context,
                            title: 'Kelola Produk',
                            subtitle: 'Stok & harga produk',
                            icon: Icons.inventory_2_outlined,
                            iconColor: AppColors.info,
                            bgColor: AppColors.info.withValues(alpha: 0.1),
                            onTap: () => context.push(AppRoutes.inventory),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionCard(
                            context,
                            title: 'Buku Piutang',
                            subtitle: 'Kasbon pelanggan',
                            icon: Icons.payments_outlined,
                            iconColor: AppColors.secondary,
                            bgColor: AppColors.secondary.withValues(alpha: 0.1),
                            onTap: () => context.push(AppRoutes.receivables),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionCard(
                            context,
                            title: 'Catat Biaya',
                            subtitle: 'Operasional toko',
                            icon: Icons.arrow_outward_rounded,
                            iconColor: AppColors.expense,
                            bgColor: AppColors.expense.withValues(alpha: 0.1),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                useRootNavigator: true,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => const AddExpenseSheet(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildWeeklyTrendChart(state, ref),

                    const SizedBox(height: 32),

                    // Transaksi Terbaru
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transaksi Terbaru',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.recap),
                          child: const Text('Lihat Semua'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (state.recentTransactions.isEmpty)
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
                                Icons.receipt_long_outlined,
                                size: 40,
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada transaksi hari ini',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...state.recentTransactions.map((tx) {
                        final hourStr = tx.createdAt.hour.toString().padLeft(
                          2,
                          '0',
                        );
                        final minStr = tx.createdAt.minute.toString().padLeft(
                          2,
                          '0',
                        );
                        final formattedTime =
                            '${tx.createdAt.day} ${_getMonthName(tx.createdAt.month)} ${tx.createdAt.year} - $hourStr:$minStr';

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
                        final txLabel = tx.paymentMethod == PaymentMethod.credit
                            ? 'Kasbon'
                            : (tx.paymentMethod == PaymentMethod.nonCash
                                  ? 'Non Tunai'
                                  : 'Tunai');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: ListTile(
                            onTap: () =>
                                _showTransactionDetailSheet(context, tx),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: txColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(txIcon, color: txColor, size: 18),
                            ),
                            title: Text(
                              txLabel,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formattedTime,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                () {
                                  final paymentDetail =
                                      TransactionNotesParser.getPaymentDetail(
                                        tx.notes,
                                      );
                                  final customNotes =
                                      TransactionNotesParser.getCustomNotes(
                                        tx.notes,
                                      );
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (paymentDetail != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          paymentDetail,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                      if (customNotes != null &&
                                          customNotes.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          customNotes,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: AppColors.textSecondary,
                                                fontStyle: FontStyle.italic,
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
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: txColor,
                              ),
                            ),
                          ),
                        );
                      }),
                    const AppFooter(),
                  ],
                ),
              ),
            );
          },
          loading: () => ShimmerLoading(),
          error: (err, stack) => Center(child: Text('Terjadi kesalahan: $err')),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendChart(DashboardState state, WidgetRef ref) {
    if (state.weeklyTrend.isEmpty) return const SizedBox.shrink();

    // Temukan nilai minimum dan maksimum untuk Y agar grafik pas secara vertikal
    double minVal = double.infinity;
    double maxVal = -double.infinity;
    for (final pt in state.weeklyTrend) {
      final values = [
        pt.income.toDouble(),
        pt.netProfit.toDouble(),
        pt.cash.toDouble(),
        pt.receivables.toDouble(),
      ];
      for (final val in values) {
        if (val < minVal) minVal = val;
        if (val > maxVal) maxVal = val;
      }
    }

    double minY;
    double maxY;
    if (minVal == double.infinity || maxVal == -double.infinity) {
      minY = 0;
      maxY = 1000.0;
    } else if (minVal == maxVal) {
      minY = minVal > 0 ? minVal * 0.8 : 0;
      maxY = maxVal > 0 ? maxVal * 1.2 : 1000.0;
    } else {
      final diff = maxVal - minVal;
      minY = minVal - (diff * 0.15);
      maxY = maxVal + (diff * 0.15);

      if (minVal >= 0 && minY < 0) {
        minY = 0;
      }
    }

    final spotsIncome = List.generate(state.weeklyTrend.length, (i) {
      return FlSpot(i.toDouble(), state.weeklyTrend[i].income.toDouble());
    });

    final spotsProfit = List.generate(state.weeklyTrend.length, (i) {
      return FlSpot(
        i.toDouble(),
        state.weeklyTrend[i].netProfit.toDouble().clamp(minY, maxY),
      );
    });

    final spotsCash = List.generate(state.weeklyTrend.length, (i) {
      return FlSpot(
        i.toDouble(),
        state.weeklyTrend[i].cash.toDouble().clamp(minY, maxY),
      );
    });

    final spotsReceivables = List.generate(state.weeklyTrend.length, (i) {
      return FlSpot(
        i.toDouble(),
        state.weeklyTrend[i].receivables.toDouble().clamp(minY, maxY),
      );
    });

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tren Keuangan',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Pemilih periode
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildPeriodChip(
                    ref,
                    state.selectedPeriod,
                    DashboardPeriod.sevenDays,
                    '7 Hari',
                  ),
                  const SizedBox(width: 8),
                  _buildPeriodChip(
                    ref,
                    state.selectedPeriod,
                    DashboardPeriod.oneMonth,
                    '1 Bulan',
                  ),
                  const SizedBox(width: 8),
                  _buildPeriodChip(
                    ref,
                    state.selectedPeriod,
                    DashboardPeriod.threeMonths,
                    '3 Bulan',
                  ),
                  const SizedBox(width: 8),
                  _buildPeriodChip(
                    ref,
                    state.selectedPeriod,
                    DashboardPeriod.sixMonths,
                    '6 Bulan',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Legenda
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _buildLegendItem('Penerimaan', AppColors.income),
                _buildLegendItem('Laba Bersih', AppColors.info),
                _buildLegendItem('Kas (Tunai)', const Color(0xFF8B5CF6)),
                _buildLegendItem('Utang (Kasbon)', AppColors.warning),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
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
                          final String label;
                          final Color color;

                          switch (touchedSpot.barIndex) {
                            case 0:
                              label = 'Penerimaan';
                              color = AppColors.income;
                              break;
                            case 1:
                              label = 'Laba';
                              color = AppColors.info;
                              break;
                            case 2:
                              label = 'Kas (Tunai)';
                              color = const Color(0xFF8B5CF6);
                              break;
                            case 3:
                            default:
                              label = 'Utang (Kasbon)';
                              color = AppColors.warning;
                              break;
                          }

                          final formattedVal = val.toRupiah();
                          return LineTooltipItem(
                            '$label: $formattedVal',
                            TextStyle(
                              fontFamily: 'GoogleSans',
                              color: color,
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
                          if (value == minY || value == maxY) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            _formatValueShort(value),
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
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
                          final idx = rounded;
                          if (idx >= 0 && idx < state.weeklyTrend.length) {
                            final label = state.weeklyTrend[idx].label;
                            if (state.selectedPeriod ==
                                    DashboardPeriod.oneMonth &&
                                idx % 5 != 0) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                label,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: -0.2,
                  maxX: (state.weeklyTrend.length - 1).toDouble() + 0.2,
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    // Line 1: Penerimaan (Hijau)
                    LineChartBarData(
                      spots: spotsIncome,
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
                    // Line 2: Laba Bersih (Biru)
                    LineChartBarData(
                      spots: spotsProfit,
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
                    // Line 3: Kas (Ungu)
                    LineChartBarData(
                      spots: spotsCash,
                      isCurved: true,
                      color: const Color(0xFF8B5CF6),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                            const Color(0xFF8B5CF6).withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Line 4: Utang (Jingga/Kuning)
                    LineChartBarData(
                      spots: spotsReceivables,
                      isCurved: true,
                      color: AppColors.warning,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.warning.withValues(alpha: 0.15),
                            AppColors.warning.withValues(alpha: 0.0),
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

  Widget _buildPeriodChip(
    WidgetRef ref,
    DashboardPeriod current,
    DashboardPeriod target,
    String label,
  ) {
    final isSelected = current == target;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: true,
      checkmarkColor: AppColors.primary,
      onSelected: (val) {
        if (val) {
          ref.read(dashboardProvider.notifier).changePeriod(target);
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
}

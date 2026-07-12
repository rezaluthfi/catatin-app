import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/router.dart';
import '../../../core/extensions/currency_extension.dart';
import '../../../data/models/transaction_model.dart';
import '../providers/dashboard_provider.dart';
import '../providers/dashboard_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

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
    final formattedTime = '${tx.createdAt.day} ${_getMonthName(tx.createdAt.month)} ${tx.createdAt.year} pukul $hourStr:$minStr';

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Waktu', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  Text(formattedTime, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Metode Pembayaran', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (tx.isCredit ? AppColors.secondary : AppColors.income).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tx.isCredit ? 'Kasbon (Piutang)' : 'Tunai',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: tx.isCredit ? AppColors.secondary : AppColors.income,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text('Daftar Produk', style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.25),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tx.items.length,
                  itemBuilder: (context, index) {
                    final item = tx.items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                Text(
                                  '${item.quantity} x ${item.sellingPriceAtTime.toRupiah()}',
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text(item.subtotal.toRupiah(), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Pembayaran', style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    tx.totalAmount.toRupiah(),
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: tx.isCredit ? AppColors.secondary : AppColors.income,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (tx.notes != null && tx.notes!.isNotEmpty) ...[
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
                        tx.notes!,
                        style: AppTextStyles.bodyMedium.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: stateAsync.when(
          data: (state) {
            final isLowStock = state.lowStockProducts.isNotEmpty;
            final isNetProfitPositive = state.netProfitToday >= 0;

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
                              Text(
                                'Selamat Datang di',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                state.businessName,
                                style: AppTextStyles.headlineMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Ringkasan Keuangan Hari Ini
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Keuangan Hari Ini',
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                // Kas Masuk
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.arrow_downward_rounded,
                                            color: AppColors.income,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 2),
                                          Expanded(
                                            child: Text(
                                              'Masuk',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          state.incomeToday.toRupiah(),
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.income,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 32,
                                  color: AppColors.border,
                                ),
                                const SizedBox(width: 8),
                                // Kas Keluar
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.arrow_upward_rounded,
                                            color: AppColors.expense,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 2),
                                          Expanded(
                                            child: Text(
                                              'Keluar',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          state.expenseToday.toRupiah(),
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.expense,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 32,
                                  color: AppColors.border,
                                ),
                                const SizedBox(width: 8),
                                // Laba Bersih
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.monetization_on_outlined,
                                            color: isNetProfitPositive
                                                ? AppColors.income
                                                : AppColors.expense,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 2),
                                          Expanded(
                                            child: Text(
                                              'Laba',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          state.netProfitToday.toRupiah(),
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isNetProfitPositive
                                                    ? AppColors.income
                                                    : AppColors.expense,
                                              ),
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

                    const SizedBox(height: 16),

                    // Grid Kartu Piutang & Stok Menipis
                    Row(
                      children: [
                        // Piutang
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            title: 'Piutang Aktif',
                            value: state.receivablesOutstanding.toRupiah(),
                            icon: Icons.payments_outlined,
                            iconColor: AppColors.secondary,
                            onTap: () => context.push(AppRoutes.receivables),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Stok Menipis Ringkasan
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            title: 'Status Stok',
                            value: isLowStock
                                ? '${state.lowStockProducts.length} Menipis'
                                : 'Aman',
                            valueColor: isLowStock
                                ? AppColors.expense
                                : AppColors.income,
                            icon: Icons.inventory_2_outlined,
                            iconColor: isLowStock
                                ? AppColors.expense
                                : AppColors.income,
                            onTap: () => context.push(AppRoutes.inventory),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildWeeklyTrendChart(state),

                    const SizedBox(height: 32),

                    // Akses Cepat (Quick Actions)
                    Text(
                      'Akses Cepat',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tombol POS Utama
                    FilledButton.icon(
                      onPressed: () => context.push(AppRoutes.pos),
                      icon: const Icon(Icons.add_shopping_cart, size: 20),
                      label: const Text('Catat Transaksi (POS)'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Menu Sekunder Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push(AppRoutes.inventory),
                            icon: const Icon(
                              Icons.inventory_2_outlined,
                              size: 20,
                            ),
                            label: const Text('Inventaris'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.push(AppRoutes.receivables),
                            icon: const Icon(
                              Icons.description_outlined,
                              size: 20,
                            ),
                            label: const Text('Buku Piutang'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

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
                        final isCredit = tx.isCredit;
                        final hourStr = tx.createdAt.hour.toString().padLeft(
                          2,
                          '0',
                        );
                        final minStr = tx.createdAt.minute.toString().padLeft(
                          2,
                          '0',
                        );
                        final formattedTime = '$hourStr:$minStr';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: ListTile(
                            onTap: () => _showTransactionDetailSheet(context, tx),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    (isCredit
                                            ? AppColors.secondary
                                            : AppColors.income)
                                        .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCredit
                                    ? Icons.payments_outlined
                                    : Icons.shopping_bag_outlined,
                                color: isCredit
                                    ? AppColors.secondary
                                    : AppColors.income,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              isCredit
                                  ? 'Kasbon (Piutang)'
                                  : 'Penjualan Langsung',
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
                                if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    tx.notes!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Text(
                              tx.totalAmount.toRupiah(),
                              style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isCredit
                                      ? AppColors.secondary
                                      : AppColors.income,
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Terjadi kesalahan: $err')),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    Color? valueColor,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendChart(DashboardState state) {
    if (state.weeklyTrend.isEmpty) return const SizedBox.shrink();

    // Temukan nilai minimum dan maksimum untuk Y agar grafik pas secara vertikal
    double minVal = double.infinity;
    double maxVal = -double.infinity;
    for (final pt in state.weeklyTrend) {
      final inc = pt.income.toDouble();
      final prof = pt.netProfit.toDouble();
      if (inc < minVal) minVal = inc;
      if (prof < minVal) minVal = prof;
      if (inc > maxVal) maxVal = inc;
      if (prof > maxVal) maxVal = prof;
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

    final Map<int, String> dayNames = {
      1: 'Sn',
      2: 'Sl',
      3: 'Rb',
      4: 'Km',
      5: 'Jm',
      6: 'Sb',
      7: 'Mg',
    };

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
              'Tren Keuangan (7 Hari Terakhir)',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Legenda
            Row(
              children: [
                _buildLegendItem('Pemasukan', AppColors.income),
                const SizedBox(width: 16),
                _buildLegendItem('Laba Bersih', AppColors.info),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => AppColors.textPrimary,
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
                              color: isRevenue
                                  ? AppColors.primaryLight
                                  : AppColors.secondaryLight,
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
                          final idx = value.toInt();
                          if (idx >= 0 && idx < state.weeklyTrend.length) {
                            final date = state.weeklyTrend[idx].date;
                            final label = dayNames[date.weekday] ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                label,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
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
                  minX: 0,
                  maxX: (state.weeklyTrend.length - 1).toDouble(),
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spotsIncome,
                      isCurved: true,
                      color: AppColors.income,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.income.withValues(alpha: 0.05),
                      ),
                    ),
                    LineChartBarData(
                      spots: spotsProfit,
                      isCurved: true,
                      color: AppColors.info,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.info.withValues(alpha: 0.05),
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

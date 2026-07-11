import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/extensions/currency_extension.dart';
import '../../../data/models/operational_cost_model.dart';
import '../providers/recap_provider.dart';
import '../providers/recap_state.dart';
import '../widgets/add_expense_sheet.dart';

class RecapScreen extends ConsumerWidget {
  const RecapScreen({super.key});

  String _getMonthName(int month) {
    return const [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ][month];
  }

  void _showAddExpense(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddExpenseSheet(),
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
              backgroundColor: AppColors.income,
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
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}jt';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}rb';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          final isProfit = state.netProfit >= 0;
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              final newDate = _adjustDate(state, -1);
                              ref.read(recapProvider.notifier).changeDate(newDate);
                            },
                          ),
                          Expanded(
                            child: Text(
                              formattedPeriod,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              final newDate = _adjustDate(state, 1);
                              ref.read(recapProvider.notifier).changeDate(newDate);
                            },
                          ),
                        ],
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
                                'Keuntungan Bersih',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textSecondary,
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

                      // Section Chart jika Bulanan
                      if (state.period == RecapPeriod.monthly &&
                          state.chartData.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildChartSection(state),
                      ],

                      const SizedBox(height: 24),

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
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.5),
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
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.operationalCosts.length,
                          itemBuilder: (context, index) {
                            final item = state.operationalCosts[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
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
                                title: Text(
                                  item.description,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item.date.day} ${_getMonthName(item.date.month)} ${item.date.year}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '- ${item.amount.toRupiah()}',
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: AppColors.expense,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.textSecondary,
                                        size: 20,
                                      ),
                                      onPressed: () => _confirmDeleteExpense(
                                        context,
                                        ref,
                                        item,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 24),

                      // Section Produk Terjual
                      Text(
                        'Produk Terjual',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                                  color: AppColors.textSecondary.withValues(alpha: 0.5),
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
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.soldProducts.length,
                          itemBuilder: (context, index) {
                            final item = state.soldProducts[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.income.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag_rounded,
                                    color: AppColors.income,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  item.name,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Terjual: ${item.quantity} pcs',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                trailing: Text(
                                  item.totalAmount.toRupiah(),
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: AppColors.income,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
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
    );
  }

  Widget _buildRowDetail(
    String label,
    String value, {
    Color? valueColor,
  }) {
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
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(RecapState state) {
    final entries = state.chartData.entries.toList();
    final keys = state.chartData.keys.toList();

    // Temukan nilai maksimum untuk penskalaan grafik Y
    int maxVal = 0;
    for (final entry in entries) {
      if (entry.value.revenue > maxVal) maxVal = entry.value.revenue;
      if (entry.value.netProfit.abs() > maxVal) {
        maxVal = entry.value.netProfit.abs();
      }
    }
    // Tambahkan 20% margin di atas nilai maksimum
    final maxScaleY = maxVal > 0 ? maxVal * 1.2 : 100000.0;

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
            Text(
              'Tren Keuangan (6 Bulan Terakhir)',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
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
                          if (value == 0) return const SizedBox();
                          return Text(
                            _formatValueShort(value),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= keys.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              keys[index],
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (keys.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxScaleY,
                  lineBarsData: [
                    // Line 1: Omzet (Revenue)
                    LineChartBarData(
                      spots: List.generate(entries.length, (i) {
                        return FlSpot(i.toDouble(), entries[i].value.revenue.toDouble());
                      }),
                      isCurved: true,
                      color: AppColors.income,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                    // Line 2: Laba Bersih (Net Profit)
                    LineChartBarData(
                      spots: List.generate(entries.length, (i) {
                        return FlSpot(
                          i.toDouble(),
                          entries[i].value.netProfit.toDouble().clamp(0.0, maxScaleY),
                        );
                      }),
                      isCurved: true,
                      color: AppColors.info,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
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

  String _getFormattedPeriodText(RecapState state) {
    final d = state.selectedDate;
    if (state.period == RecapPeriod.daily) {
      return '${d.day} ${_getMonthName(d.month)} ${d.year}';
    } else if (state.period == RecapPeriod.weekly) {
      final weekday = d.weekday;
      final start = d.subtract(Duration(days: weekday - 1));
      final end = start.add(const Duration(days: 6));
      return '${start.day} ${_getMonthName(start.month).substring(0, 3)} - ${end.day} ${_getMonthName(end.month).substring(0, 3)} ${end.year}';
    } else {
      return '${_getMonthName(d.month)} ${d.year}';
    }
  }

  DateTime _adjustDate(RecapState state, int offset) {
    final d = state.selectedDate;
    if (state.period == RecapPeriod.daily) {
      return d.add(Duration(days: offset));
    } else if (state.period == RecapPeriod.weekly) {
      return d.add(Duration(days: offset * 7));
    } else {
      return DateTime(d.year, d.month + offset, 1);
    }
  }
}

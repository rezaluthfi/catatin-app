import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/extensions/currency_extension.dart';
import '../../../data/models/receivable_model.dart';
import '../providers/receivable_provider.dart';

class ReceivablePaymentSheet extends ConsumerStatefulWidget {
  const ReceivablePaymentSheet({
    super.key,
    required this.receivable,
  });

  final ReceivableModel receivable;

  @override
  ConsumerState<ReceivablePaymentSheet> createState() =>
      _ReceivablePaymentSheetState();
}

class _ReceivablePaymentSheetState extends ConsumerState<ReceivablePaymentSheet> {
  final _amountController = TextEditingController();
  bool _submitted = false;
  int _paymentAmount = 0;
  bool _payInFull = true;

  @override
  void initState() {
    super.initState();
    // Default payment is the remaining amount (full payment)
    _paymentAmount = widget.receivable.remainingAmount;
    _amountController.text = _paymentAmount.toRupiahNoSymbol();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String value) {
    final numericString = value.replaceAll(RegExp(r'[^0-9]'), '');
    final intValue = int.tryParse(numericString) ?? 0;

    if (numericString.isNotEmpty) {
      final formatted = intValue.toRupiahNoSymbol();
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else {
      _amountController.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    setState(() {
      _paymentAmount = intValue;
    });
  }

  void _submitPayment() async {
    setState(() {
      _submitted = true;
    });

    if (_payInFull) {
      _paymentAmount = widget.receivable.remainingAmount;
    }

    if (_paymentAmount <= 0) {
      return;
    }

    if (_paymentAmount > widget.receivable.remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal pembayaran melebihi sisa utang'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final success = await ref
        .read(receivableProvider.notifier)
        .addPayment(widget.receivable.id, _paymentAmount);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran berhasil dicatat!'),
          backgroundColor: AppColors.income,
        ),
      );
    } else {
      final errorMsg = ref.read(receivableProvider).value?.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg ?? 'Gagal mencatat pembayaran'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  String _getMonthName(int month) {
    return const [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ][month];
  }

  @override
  Widget build(BuildContext context) {
    final receivableState = ref.watch(receivableProvider);
    final isLoading = receivableState.value?.isLoading ?? false;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Catat Pembayaran',
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Rincian Piutang
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildRowInfo('Pelanggan', widget.receivable.customerName, isBold: true),
                        const SizedBox(height: 8),
                        _buildRowInfo('Total Piutang', widget.receivable.amount.toRupiah()),
                        const SizedBox(height: 8),
                        _buildRowInfo('Sudah Dibayar', widget.receivable.paidAmount.toRupiah()),
                        const Divider(height: 16),
                        _buildRowInfo(
                          'Sisa Piutang',
                          widget.receivable.remainingAmount.toRupiah(),
                          valueColor: AppColors.expense,
                          isBold: true,
                        ),
                        if (widget.receivable.dueDate != null) ...[
                          const SizedBox(height: 8),
                          _buildRowInfo(
                            'Jatuh Tempo',
                            '${widget.receivable.dueDate!.day} ${_getMonthName(widget.receivable.dueDate!.month)} ${widget.receivable.dueDate!.year}',
                            valueColor: widget.receivable.dueDate!.isBefore(DateTime.now()) &&
                                    !widget.receivable.isPaid
                                ? AppColors.expense
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Segmented Button untuk Mode Pembayaran
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('Bayar Lunas'),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Cicil / Sebagian'),
                      ),
                    ],
                    selected: {_payInFull},
                    onSelectionChanged: (val) {
                      setState(() {
                        _payInFull = val.first;
                        if (_payInFull) {
                          _paymentAmount = widget.receivable.remainingAmount;
                          _amountController.text = _paymentAmount.toRupiahNoSymbol();
                        } else {
                          _paymentAmount = 0;
                          _amountController.clear();
                        }
                        _submitted = false;
                      });
                    },
                    showSelectedIcon: false,
                  ),

                  const SizedBox(height: 24),

                  if (_payInFull) ...[
                    // Info Bayar Lunas
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.income.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.income.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppColors.income),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Akan dicatat pembayaran lunas sebesar ${widget.receivable.remainingAmount.toRupiah()}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.income,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Input Nominal Cicilan
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      onChanged: _onAmountChanged,
                      decoration: InputDecoration(
                        labelText: 'Nominal Cicilan (Rp)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixText: 'Rp ',
                        errorText: _submitted && _paymentAmount <= 0
                            ? 'Nominal pembayaran tidak valid'
                            : null,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                   FilledButton(
                    onPressed: isLoading ? null : _submitPayment,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_payInFull ? 'Lunasi Piutang' : 'Simpan Pembayaran Cicilan'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowInfo(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

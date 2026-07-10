import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/extensions/currency_extension.dart';
import '../../../data/models/transaction_enums.dart';
import '../providers/pos_provider.dart';

class CheckoutBottomSheet extends ConsumerStatefulWidget {
  const CheckoutBottomSheet({super.key, this.onBackToCart});

  final VoidCallback? onBackToCart;

  @override
  ConsumerState<CheckoutBottomSheet> createState() =>
      _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends ConsumerState<CheckoutBottomSheet> {
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  int _cashReceived = 0;
  final _notesController = TextEditingController();
  final _cashController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    _cashController.dispose();
    super.dispose();
  }

  void _onCashChanged(String value) {
    // Menghapus format non-digit
    final numericString = value.replaceAll(RegExp(r'[^0-9]'), '');
    final intValue = int.tryParse(numericString) ?? 0;

    if (numericString.isNotEmpty) {
      final formatted = intValue.toRupiahNoSymbol();
      _cashController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else {
      _cashController.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    setState(() {
      _cashReceived = intValue;
    });
  }

  void _submitTransaction() async {
    final posState = ref.read(posProvider);
    final total = posState.totalAmount;

    if (_paymentMethod == PaymentMethod.cash && _cashReceived < total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uang tunai kurang dari total tagihan'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final success = await ref
        .read(posProvider.notifier)
        .checkout(
          paymentMethod: _paymentMethod,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context); // Tutup bottom sheet checkout
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil disimpan!'),
          backgroundColor: AppColors.income,
        ),
      );
    } else {
      final errorMsg = ref.read(posProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg ?? 'Gagal menyimpan transaksi'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final posState = ref.watch(posProvider);
    final totalAmount = posState.totalAmount;
    final change = _cashReceived - totalAmount;
    final hasEnteredCash = _cashController.text.isNotEmpty;
    final isError = hasEnteredCash && change < 0;
    final isSuccess = hasEnteredCash && change >= 0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                if (widget.onBackToCart != null) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: widget.onBackToCart,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  'Pembayaran',
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                  // Tipe Pembayaran
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<PaymentMethod>(
                          title: const Text('Tunai'),
                          value: PaymentMethod.cash,
                          groupValue: _paymentMethod,
                          onChanged: (val) {
                            setState(() {
                              _paymentMethod = val!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<PaymentMethod>(
                          title: const Text('Kasbon'),
                          value: PaymentMethod.credit,
                          groupValue: _paymentMethod,
                          onChanged: (val) {
                            setState(() {
                              _paymentMethod = val!;
                              _cashReceived = 0;
                              _cashController.clear();
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (_paymentMethod == PaymentMethod.cash) ...[
                    TextField(
                      controller: _cashController,
                      keyboardType: TextInputType.number,
                      onChanged: _onCashChanged,
                      decoration: InputDecoration(
                        labelText: 'Nominal Uang Diterima (Rp)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixText: 'Rp ',
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSuccess
                            ? AppColors.income.withValues(alpha: 0.1)
                            : (isError
                                  ? AppColors.expense.withValues(alpha: 0.1)
                                  : AppColors.surfaceVariant.withValues(
                                      alpha: 0.5,
                                    )),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Kembalian', style: AppTextStyles.headingSmall),
                          Text(
                            !hasEnteredCash
                                ? 'Rp 0'
                                : (isSuccess
                                      ? change.toRupiah()
                                      : 'Uang Kurang'),
                            style: AppTextStyles.headingMedium.copyWith(
                              color: isSuccess
                                  ? AppColors.income
                                  : (isError
                                        ? AppColors.expense
                                        : AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Catatan (Opsional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Misal: Nama pelanggan',
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Tagihan', style: AppTextStyles.headingSmall),
                      Text(
                        totalAmount.toRupiah(),
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: posState.isLoading ? null : _submitTransaction,
                    child: posState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Selesaikan Transaksi'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

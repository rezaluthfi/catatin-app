import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/extensions/currency_extension.dart';
import '../providers/pos_provider.dart';

class CartBottomSheet extends ConsumerWidget {
  const CartBottomSheet({
    super.key,
    required this.onCheckout,
  });

  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posState = ref.watch(posProvider);
    final cartItems = posState.cartItems;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
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
          // Handle drag / header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Keranjang Belanja',
                  style: AppTextStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(posProvider.notifier).clearCart();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Kosongkan',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.expense),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Daftar Item
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: cartItems.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      // Info produk
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtotal.toRupiah(),
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.income),
                            ),
                          ],
                        ),
                      ),
                      
                      // Kontrol Kuantitas
                      Row(
                        children: [
                          _buildQtyButton(
                            icon: Icons.remove,
                            onTap: () => ref.read(posProvider.notifier).decrementQuantity(item.product),
                          ),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '${item.quantity}',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          _buildQtyButton(
                            icon: Icons.add,
                            onTap: () => ref.read(posProvider.notifier).addToCart(item.product),
                            isDisabled: item.quantity >= item.product.stock,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),
          // Ringkasan Harga
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Tagihan', style: AppTextStyles.headingSmall),
                    Text(
                      posState.totalAmount.toRupiah(),
                      style: AppTextStyles.headingMedium.copyWith(color: AppColors.income),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: cartItems.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context);
                          onCheckout();
                        },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Lanjut Pembayaran'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return Material(
      color: isDisabled ? AppColors.surfaceVariant : AppColors.primaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            size: 16,
            color: isDisabled ? AppColors.textSecondary : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

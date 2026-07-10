import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/extensions/currency_extension.dart';
import '../models/cart_item_model.dart';
import '../providers/pos_provider.dart';

class CartBottomSheet extends ConsumerWidget {
  const CartBottomSheet({super.key, required this.onCheckout});

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
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Stack(
              alignment: Alignment
                  .centerLeft, // Menggunakan alignment kiri untuk menyamakan dengan Checkout
              children: [
                Text(
                  'Keranjang Belanja',
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Positioned(
                  right: 0,
                  child: TextButton(
                    onPressed: () {
                      ref.read(posProvider.notifier).clearCart();
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Kosongkan',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.expense,
                      ),
                    ),
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
                return _CartItemRow(item: item);
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
                      style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.income,
                      ),
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
                  child: const Text('Lanjut Pembayaran'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemRow extends ConsumerStatefulWidget {
  const _CartItemRow({required this.item});
  final CartItemModel item;

  @override
  ConsumerState<_CartItemRow> createState() => _CartItemRowState();
}

class _CartItemRowState extends ConsumerState<_CartItemRow> {
  late TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _CartItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.quantity != widget.item.quantity) {
      _qtyController.text = widget.item.quantity.toString();
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _submitQty() {
    final newQty = int.tryParse(_qtyController.text) ?? 0;
    if (newQty > 0) {
      ref.read(posProvider.notifier).setQuantity(widget.item.product, newQty);
    } else {
      _qtyController.text = widget.item.quantity.toString();
    }
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

  @override
  Widget build(BuildContext context) {
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
                  widget.item.product.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.subtotal.toRupiah(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.income,
                  ),
                ),
              ],
            ),
          ),

          // Kontrol Kuantitas
          Row(
            children: [
              _buildQtyButton(
                icon: Icons.remove,
                onTap: () => ref
                    .read(posProvider.notifier)
                    .decrementQuantity(widget.item.product),
              ),
              Container(
                width: 44,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.only(
                      bottom: 2,
                    ), // sedikit offset agar pas tengah
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _submitQty(),
                  onTapOutside: (_) {
                    FocusScope.of(context).unfocus();
                    _submitQty();
                  },
                ),
              ),
              _buildQtyButton(
                icon: Icons.add,
                onTap: () => ref
                    .read(posProvider.notifier)
                    .addToCart(widget.item.product),
                isDisabled: widget.item.quantity >= widget.item.product.stock,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

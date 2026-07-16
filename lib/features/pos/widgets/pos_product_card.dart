import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/extensions/currency_extension.dart';
import '../../../data/models/product_model.dart';
import '../providers/pos_provider.dart';

class PosProductCard extends ConsumerWidget {
  const PosProductCard({
    super.key,
    required this.product,
  });

  final ProductModel product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cari apakah produk ini ada di keranjang
    final cartItems = ref.watch(posProvider).cartItems;
    final cartItem = cartItems.where((c) => c.product.id == product.id).firstOrNull;
    final int qtyInCart = cartItem?.quantity ?? 0;

    final isLowStock = product.isLowStock;
    final isOutOfStock = product.isOutOfStock;
    // Jika stok sisa 0, maka tidak bisa ditambah ke keranjang lagi
    final bool canAdd = !isOutOfStock && qtyInCart < product.stock;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOutOfStock
              ? AppColors.expense.withValues(alpha: 0.5)
              : (qtyInCart > 0)
                  ? AppColors.income
                  : isLowStock
                      ? AppColors.warning.withValues(alpha: 0.5)
                      : AppColors.border,
          width: 1,
        ),
      ),
      color: isOutOfStock
          ? AppColors.errorContainer
          : (qtyInCart > 0)
              ? AppColors.income.withValues(alpha: 0.05)
              : isLowStock
                  ? AppColors.warningContainer
                  : AppColors.surface,
      child: Stack(
        children: [
          // Konten utama kartu
          InkWell(
            onTap: () {
              if (canAdd) {
                ref.read(posProvider.notifier).addToCart(product);
              } else if (isOutOfStock) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} sudah habis!'),
                    backgroundColor: AppColors.expense,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Jumlah pembelian ${product.name} mencapai batas maksimum stok (${product.stock} pcs)',
                    ),
                    backgroundColor: AppColors.expense,
                  ),
                );
              }
            },
            child: Opacity(
              opacity: isOutOfStock ? 0.6 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    color: isOutOfStock
                        ? AppColors.expense.withValues(alpha: 0.1)
                        : isLowStock
                            ? AppColors.warning.withValues(alpha: 0.1)
                            : (qtyInCart > 0)
                                ? AppColors.income.withValues(alpha: 0.1)
                                : AppColors.primary.withValues(alpha: 0.05),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      size: 40,
                      color: isOutOfStock
                          ? AppColors.expense.withValues(alpha: 0.5)
                          : isLowStock
                              ? AppColors.warning.withValues(alpha: 0.5)
                              : (qtyInCart > 0)
                                  ? AppColors.income.withValues(alpha: 0.5)
                                  : AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTextStyles.headingSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            product.sellingPrice.toRupiah(),
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.income,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOutOfStock ? 'Habis' : 'Stok: ${product.stock}',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isOutOfStock
                                ? AppColors.expense
                                : isLowStock
                                    ? AppColors.warning
                                    : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
          
          // Badge kuantitas jika ada di keranjang
          if (qtyInCart > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.income,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '${qtyInCart}x',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

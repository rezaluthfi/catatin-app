import 'package:flutter/material.dart';

import 'dart:io';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/extensions/currency_extension.dart';
import '../../../data/models/product_model.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.isLowStock;
    final isOutOfStock = product.isOutOfStock;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOutOfStock
              ? AppColors.expense.withValues(alpha: 0.5)
              : isLowStock
              ? AppColors.warning.withValues(alpha: 0.5)
              : AppColors.border,
          width: 1,
        ),
      ),
      color: isOutOfStock
          ? AppColors.errorContainer
          : isLowStock
          ? AppColors.warningContainer
          : AppColors.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                    : AppColors.primary.withValues(alpha: 0.05),
                child: _buildProductImage(isOutOfStock, isLowStock),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: AppTextStyles.headingSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStockBadge(),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Harga Jual', style: AppTextStyles.labelSmall),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            product.sellingPrice.toRupiah(),
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Harga Beli', style: AppTextStyles.labelSmall),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            product.purchasePrice.toRupiah(),
                            style: AppTextStyles.bodyMediumSecondary.copyWith(
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildStockBadge() {
    final isLowStock = product.isLowStock;
    final isOutOfStock = product.isOutOfStock;

    Color badgeColor = AppColors.primaryContainer;
    Color textColor = AppColors.primary;

    if (isOutOfStock) {
      badgeColor = AppColors.expense;
      textColor = Colors.white;
    } else if (isLowStock) {
      badgeColor = AppColors.warning;
      textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isOutOfStock ? 'Habis' : 'Stok: ${product.stock}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelMedium.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildProductImage(bool isOutOfStock, bool isLowStock) {
    if (product.imagePath != null && product.imagePath!.isNotEmpty) {
      final file = File(product.imagePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }
    }
    return Icon(
      Icons.inventory_2_rounded,
      size: 40,
      color: isOutOfStock
          ? AppColors.expense.withValues(alpha: 0.5)
          : isLowStock
          ? AppColors.warning.withValues(alpha: 0.5)
          : AppColors.primary.withValues(alpha: 0.3),
    );
  }
}

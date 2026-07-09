import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

class EmptyInventoryWidget extends StatelessWidget {
  const EmptyInventoryWidget({
    super.key,
    this.isSearch = false,
  });

  final bool isSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearch ? Icons.search_off_rounded : Icons.inventory_2_outlined,
              size: 80,
              color: AppColors.border,
            ),
            const SizedBox(height: 16),
            Text(
              isSearch ? 'Tidak ada produk ditemukan' : 'Belum ada produk',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearch
                  ? 'Coba gunakan kata kunci lain untuk mencari.'
                  : 'Tambahkan produk pertama kamu untuk mulai berjualan.',
              style: AppTextStyles.bodyMediumSecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

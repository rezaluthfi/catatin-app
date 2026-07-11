import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/extensions/currency_extension.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../../inventory/widgets/empty_inventory_widget.dart';
import '../providers/pos_provider.dart';
import '../widgets/cart_bottom_sheet.dart';
import '../widgets/checkout_bottom_sheet.dart';
import '../widgets/pos_product_card.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CartBottomSheet(
        onCheckout: _showCheckoutSheet,
      ),
    );
  }

  void _showCheckoutSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CheckoutBottomSheet(
        onBackToCart: () {
          Navigator.pop(context);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showCartSheet();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kita gunakan inventoryProvider untuk list produk, tapi query pencariannya dari posProvider
    final posState = ref.watch(posProvider);
    final cartItems = posState.cartItems;
    final totalItems = posState.totalItems;
    final totalAmount = posState.totalAmount;

    // Untuk simpelnya, kita filter list inventory di lokal sini agar tidak mengacaukan filter layar Inventaris
    final inventoryState = ref.watch(inventoryProvider).valueOrNull;
    final allProducts = inventoryState?.products ?? [];
    
    final searchQuery = posState.searchQuery.toLowerCase();
    final displayedProducts = allProducts.where((p) {
      if (searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Catat Transaksi', style: AppTextStyles.headlineMedium),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                ref.read(posProvider.notifier).setSearchQuery(val);
              },
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                hintStyle: AppTextStyles.bodyMediumSecondary,
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(posProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Daftar Produk (Grid)
          Expanded(
            child: displayedProducts.isEmpty
                ? EmptyInventoryWidget(isSearch: searchQuery.isNotEmpty)
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 100), // padding bawah untuk bottom bar
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: displayedProducts.length,
                    itemBuilder: (context, index) {
                      return PosProductCard(product: displayedProducts[index]);
                    },
                  ),
          ),
        ],
      ),
      
      // Floating Bottom Bar untuk Keranjang
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: cartItems.isEmpty
          ? null
          : Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showCartSheet,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$totalItems',
                                  style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Belanja',
                                      style: AppTextStyles.labelSmall.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                                    ),
                                    Text(
                                      totalAmount.toRupiah(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.headingSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            Text(
                              'Lihat',
                              style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

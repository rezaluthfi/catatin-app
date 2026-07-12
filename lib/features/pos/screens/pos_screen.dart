// ignore_for_file: deprecated_member_use
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
import '../../inventory/providers/inventory_state.dart';
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
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Catat Transaksi', style: AppTextStyles.headlineMedium),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded, color: AppColors.textPrimary),
            onPressed: () => _showSortModal(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
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

  void _showSortModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentState = ref.watch(inventoryProvider).valueOrNull;
            if (currentState == null) return const SizedBox();

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Filter', style: AppTextStyles.headlineSmall),
                          (() {
                            final hasFilters = currentState.showLowStockOnly || currentState.showOutOfStockOnly;
                            final hasDefaultSort = currentState.sortTypes.length == 1 && currentState.sortTypes.first == ProductSortType.nameAsc;
                            final isDirty = hasFilters || !hasDefaultSort;
                            if (isDirty) {
                              return TextButton(
                                onPressed: () {
                                  ref.read(inventoryProvider.notifier).clearFilters();
                                  Navigator.pop(context);
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Reset'),
                              );
                            }
                            return const SizedBox();
                          })(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFilterOption(
                      context,
                      ref,
                      title: 'Tampilkan Stok Menipis Saja',
                      value: currentState.showLowStockOnly,
                      onChanged: (_) {
                        ref.read(inventoryProvider.notifier).toggleLowStockFilter();
                        Navigator.pop(context);
                      },
                    ),
                    _buildFilterOption(
                      context,
                      ref,
                      title: 'Tampilkan Stok Habis Saja',
                      value: currentState.showOutOfStockOnly,
                      onChanged: (_) {
                        ref.read(inventoryProvider.notifier).toggleOutOfStockFilter();
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text('Urutkan Berdasarkan', style: AppTextStyles.headlineSmall),
                    ),
                    const SizedBox(height: 8),
                    _buildSortOption(
                      context,
                      ref,
                      title: 'Nama (A-Z)',
                      value: ProductSortType.nameAsc,
                      sortTypes: currentState.sortTypes,
                    ),
                    _buildSortOption(
                      context,
                      ref,
                      title: 'Nama (Z-A)',
                      value: ProductSortType.nameDesc,
                      sortTypes: currentState.sortTypes,
                    ),
                    _buildSortOption(
                      context,
                      ref,
                      title: 'Stok Terbanyak',
                      value: ProductSortType.stockDesc,
                      sortTypes: currentState.sortTypes,
                    ),
                    _buildSortOption(
                      context,
                      ref,
                      title: 'Stok Sedikit',
                      value: ProductSortType.stockAsc,
                      sortTypes: currentState.sortTypes,
                    ),
                    _buildSortOption(
                      context,
                      ref,
                      title: 'Harga Tertinggi',
                      value: ProductSortType.priceDesc,
                      sortTypes: currentState.sortTypes,
                    ),
                    _buildSortOption(
                      context,
                      ref,
                      title: 'Harga Terendah',
                      value: ProductSortType.priceAsc,
                      sortTypes: currentState.sortTypes,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Terapkan'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: value ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      activeColor: AppColors.primary,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required ProductSortType value,
    required List<ProductSortType> sortTypes,
  }) {
    final index = sortTypes.indexOf(value);
    final isSelected = index >= 0;

    return CheckboxListTile(
      value: isSelected,
      onChanged: (_) {
        ref.read(inventoryProvider.notifier).toggleSortType(value);
      },
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      activeColor: AppColors.primary,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}

// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../providers/inventory_provider.dart';
import '../providers/inventory_state.dart';
import '../widgets/empty_inventory_widget.dart';
import '../widgets/product_card.dart';
import '../../../core/widgets/app_footer.dart';

class InventoryListScreen extends ConsumerWidget {
  const InventoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryState = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Inventaris Produk', style: AppTextStyles.headlineMedium),
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
          _buildSearchBar(context, ref),
          Expanded(
            child: inventoryState.when(
              data: (state) {
                if (state.products.isEmpty) {
                  return Column(
                    children: [
                      Expanded(
                        child: EmptyInventoryWidget(
                          isSearch: state.searchQuery.isNotEmpty,
                        ),
                      ),
                      const AppFooter(hasFAB: true),
                    ],
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(inventoryProvider.notifier).reload(),
                  color: AppColors.primary,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.6,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = state.products[index];
                              return ProductCard(
                                product: product,
                                onTap: () {
                                  context.push(
                                    AppRoutes.productEdit.replaceFirst(
                                      ':id',
                                      product.id,
                                    ),
                                  );
                                },
                              );
                            },
                            childCount: state.products.length,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: AppFooter(hasFAB: true),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'Gagal memuat produk:\n$error',
                  style: AppTextStyles.bodyMediumSecondary,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: MediaQuery.of(context).viewInsets.bottom > 0
          ? null
          : FloatingActionButton(
              heroTag: null,
              onPressed: () => context.push(AppRoutes.productAdd),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded),
            ),
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    return const _SearchBar();
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
                            final hasFilters =
                                currentState.showLowStockOnly ||
                                currentState.showOutOfStockOnly;
                            final hasDefaultSort =
                                currentState.sortTypes.length == 1 &&
                                currentState.sortTypes.first ==
                                    ProductSortType.nameAsc;
                            final isDirty = hasFilters || !hasDefaultSort;
                            if (isDirty) {
                              return TextButton(
                                onPressed: () {
                                  ref
                                      .read(inventoryProvider.notifier)
                                      .clearFilters();
                                  Navigator.pop(context);
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
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
                        ref
                            .read(inventoryProvider.notifier)
                            .toggleLowStockFilter();
                        Navigator.pop(context);
                      },
                    ),
                    _buildFilterOption(
                      context,
                      ref,
                      title: 'Tampilkan Stok Habis Saja',
                      value: currentState.showOutOfStockOnly,
                      onChanged: (_) {
                        ref
                            .read(inventoryProvider.notifier)
                            .toggleOutOfStockFilter();
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Urutkan Berdasarkan',
                        style: AppTextStyles.headlineSmall,
                      ),
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

class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery =
        ref.watch(inventoryProvider).valueOrNull?.searchQuery ?? '';

    // Sinkronisasi teks jika dikosongkan dari luar (opsional)
    if (searchQuery.isEmpty && _controller.text.isNotEmpty) {
      _controller.clear();
    }

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: TextField(
        controller: _controller,
        onChanged: (val) {
          ref.read(inventoryProvider.notifier).setSearchQuery(val);
        },
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          hintStyle: AppTextStyles.bodyMediumSecondary,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    _controller.clear();
                    ref.read(inventoryProvider.notifier).setSearchQuery('');
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
    );
  }
}

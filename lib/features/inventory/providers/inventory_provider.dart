import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../data/models/product_model.dart';
import 'inventory_state.dart';

final inventoryProvider =
    AsyncNotifierProvider<InventoryNotifier, InventoryState>(
  InventoryNotifier.new,
);

class InventoryNotifier extends AsyncNotifier<InventoryState> {
  @override
  FutureOr<InventoryState> build() async {
    return _loadData(const InventoryState());
  }

  Future<InventoryState> _loadData(InventoryState currentState) async {
    final repo = ref.read(productRepositoryProvider);
    List<ProductModel> products;

    if (currentState.searchQuery.isNotEmpty) {
      products = await repo.search(currentState.searchQuery);
    } else {
      products = await repo.getAll();
    }

    // Apply filters
    if (currentState.showOutOfStockOnly) {
      products = products.where((p) => p.isOutOfStock).toList();
    } else if (currentState.showLowStockOnly) {
      products = products.where((p) => p.isLowStock).toList();
    }

    // Apply sorting
    products = List.from(products); // make mutable copy for sorting
    products.sort((a, b) {
      for (final sort in currentState.sortTypes) {
        int cmp = 0;
        switch (sort) {
          case ProductSortType.nameAsc:
            cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
            break;
          case ProductSortType.nameDesc:
            cmp = b.name.toLowerCase().compareTo(a.name.toLowerCase());
            break;
          case ProductSortType.stockAsc:
            cmp = a.stock.compareTo(b.stock);
            break;
          case ProductSortType.stockDesc:
            cmp = b.stock.compareTo(a.stock);
            break;
          case ProductSortType.priceAsc:
            cmp = a.sellingPrice.compareTo(b.sellingPrice);
            break;
          case ProductSortType.priceDesc:
            cmp = b.sellingPrice.compareTo(a.sellingPrice);
            break;
        }
        if (cmp != 0) return cmp;
      }
      return 0;
    });

    return currentState.copyWith(products: products);
  }

  Future<void> reload() async {
    if (state.value == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadData(state.value!));
  }

  Future<void> setSearchQuery(String query) async {
    if (state.value == null) return;
    final newState = state.value!.copyWith(searchQuery: query);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadData(newState));
  }

  Future<void> toggleSortType(ProductSortType sortType) async {
    if (state.value == null) return;
    
    final currentList = List<ProductSortType>.from(state.value!.sortTypes);
    
    ProductSortType? conflictingType;
    switch (sortType) {
      case ProductSortType.nameAsc:
        conflictingType = ProductSortType.nameDesc;
        break;
      case ProductSortType.nameDesc:
        conflictingType = ProductSortType.nameAsc;
        break;
      case ProductSortType.stockAsc:
        conflictingType = ProductSortType.stockDesc;
        break;
      case ProductSortType.stockDesc:
        conflictingType = ProductSortType.stockAsc;
        break;
      case ProductSortType.priceAsc:
        conflictingType = ProductSortType.priceDesc;
        break;
      case ProductSortType.priceDesc:
        conflictingType = ProductSortType.priceAsc;
        break;
    }
    
    if (currentList.contains(sortType)) {
      currentList.remove(sortType);
    } else {
      currentList.remove(conflictingType);
      currentList.insert(0, sortType);
    }
    
    if (currentList.isEmpty) {
      currentList.add(ProductSortType.nameAsc);
    }
    
    final newState = state.value!.copyWith(sortTypes: currentList);
    state = await AsyncValue.guard(() => _loadData(newState));
  }

  Future<void> toggleLowStockFilter() async {
    if (state.value == null) return;
    final newState = state.value!.copyWith(
      showLowStockOnly: !state.value!.showLowStockOnly,
      // If toggling low stock on, we might want to turn off out of stock
      showOutOfStockOnly: false,
    );
    state = await AsyncValue.guard(() => _loadData(newState));
  }

  Future<void> toggleOutOfStockFilter() async {
    if (state.value == null) return;
    final newState = state.value!.copyWith(
      showOutOfStockOnly: !state.value!.showOutOfStockOnly,
      // If toggling out of stock on, we might want to turn off low stock
      showLowStockOnly: false,
    );
    state = await AsyncValue.guard(() => _loadData(newState));
  }

  Future<void> clearFilters() async {
    if (state.value == null) return;
    final newState = state.value!.copyWith(
      showLowStockOnly: false,
      showOutOfStockOnly: false,
      sortTypes: const [ProductSortType.nameAsc],
    );
    state = await AsyncValue.guard(() => _loadData(newState));
  }

  Future<void> addProduct(ProductModel product) async {
    final repo = ref.read(productRepositoryProvider);
    await repo.insert(product);
    await reload();
  }

  Future<void> updateProduct(ProductModel product) async {
    final repo = ref.read(productRepositoryProvider);
    await repo.update(product);
    await reload();
  }

  Future<void> deleteProduct(String id) async {
    final repo = ref.read(productRepositoryProvider);
    await repo.delete(id);
    await reload();
  }
}

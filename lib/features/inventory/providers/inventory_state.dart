import '../../../data/models/product_model.dart';

enum ProductSortType {
  nameAsc,
  nameDesc,
  stockAsc,
  stockDesc,
}

class InventoryState {
  const InventoryState({
    this.products = const [],
    this.searchQuery = '',
    this.sortType = ProductSortType.nameAsc,
    this.showLowStockOnly = false,
    this.showOutOfStockOnly = false,
  });

  final List<ProductModel> products;
  final String searchQuery;
  final ProductSortType sortType;
  final bool showLowStockOnly;
  final bool showOutOfStockOnly;

  InventoryState copyWith({
    List<ProductModel>? products,
    String? searchQuery,
    ProductSortType? sortType,
    bool? showLowStockOnly,
    bool? showOutOfStockOnly,
  }) {
    return InventoryState(
      products: products ?? this.products,
      searchQuery: searchQuery ?? this.searchQuery,
      sortType: sortType ?? this.sortType,
      showLowStockOnly: showLowStockOnly ?? this.showLowStockOnly,
      showOutOfStockOnly: showOutOfStockOnly ?? this.showOutOfStockOnly,
    );
  }
}

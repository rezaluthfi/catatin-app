import '../../../data/models/product_model.dart';

enum ProductSortType {
  nameAsc,
  nameDesc,
  stockAsc,
  stockDesc,
  priceAsc,
  priceDesc,
}

class InventoryState {
  const InventoryState({
    this.products = const [],
    this.searchQuery = '',
    this.sortTypes = const [ProductSortType.nameAsc],
    this.showLowStockOnly = false,
    this.showOutOfStockOnly = false,
  });

  final List<ProductModel> products;
  final String searchQuery;
  final List<ProductSortType> sortTypes;
  final bool showLowStockOnly;
  final bool showOutOfStockOnly;

  InventoryState copyWith({
    List<ProductModel>? products,
    String? searchQuery,
    List<ProductSortType>? sortTypes,
    bool? showLowStockOnly,
    bool? showOutOfStockOnly,
  }) {
    return InventoryState(
      products: products ?? this.products,
      searchQuery: searchQuery ?? this.searchQuery,
      sortTypes: sortTypes ?? this.sortTypes,
      showLowStockOnly: showLowStockOnly ?? this.showLowStockOnly,
      showOutOfStockOnly: showOutOfStockOnly ?? this.showOutOfStockOnly,
    );
  }
}

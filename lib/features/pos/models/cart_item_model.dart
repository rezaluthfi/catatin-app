import '../../../data/models/product_model.dart';

/// Merepresentasikan satu baris item yang ada di keranjang belanja (Cart).
class CartItemModel {
  const CartItemModel({
    required this.product,
    this.quantity = 1,
  });

  final ProductModel product;
  final int quantity;

  /// Harga subtotal = harga jual produk * kuantitas
  int get subtotal => product.sellingPrice * quantity;

  /// Keuntungan subtotal = (harga jual - harga beli) * kuantitas
  int get subtotalProfit => (product.sellingPrice - product.purchasePrice) * quantity;

  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItemModel &&
          runtimeType == other.runtimeType &&
          product.id == other.product.id &&
          quantity == other.quantity;

  @override
  int get hashCode => product.id.hashCode ^ quantity.hashCode;
}

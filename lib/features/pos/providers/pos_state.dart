import '../models/cart_item_model.dart';

/// State untuk fitur POS (Point of Sale).
class PosState {
  const PosState({
    this.cartItems = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  /// Daftar item di keranjang belanja.
  final List<CartItemModel> cartItems;

  /// Teks pencarian untuk menyaring produk di layar POS.
  final String searchQuery;

  /// Status loading (misal saat proses checkout).
  final bool isLoading;

  /// Pesan error jika ada.
  final String? errorMessage;

  /// Menghitung total tagihan dari semua item di keranjang.
  int get totalAmount => cartItems.fold(
        0,
        (sum, item) => sum + item.subtotal,
      );

  /// Menghitung total kuantitas barang di keranjang.
  int get totalItems => cartItems.fold(
        0,
        (sum, item) => sum + item.quantity,
      );

  PosState copyWith({
    List<CartItemModel>? cartItems,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PosState(
      cartItems: cartItems ?? this.cartItems,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // bisa null
    );
  }

  /// Helper khusus untuk membersihkan error tanpa harus menimpa field lain.
  PosState clearError() {
    return PosState(
      cartItems: cartItems,
      searchQuery: searchQuery,
      isLoading: isLoading,
      errorMessage: null,
    );
  }
}

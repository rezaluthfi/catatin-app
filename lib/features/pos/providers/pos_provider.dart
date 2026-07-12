import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../data/models/transaction_enums.dart';
import '../../../data/models/transaction_item_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/receivable_model.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../../receivables/providers/receivable_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../recap/providers/recap_provider.dart';
import '../models/cart_item_model.dart';
import 'pos_state.dart';

final posProvider = NotifierProvider<PosNotifier, PosState>(() {
  return PosNotifier();
});

class PosNotifier extends Notifier<PosState> {
  @override
  PosState build() {
    return const PosState();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void addToCart(ProductModel product) {
    // Cek apakah stok cukup? (Bisa jadi peringatan kalau lebih dari stok, tapi untuk UMKM mungkin biarkan saja dan biarkan stok minus,
    // tapi lebih baik kita batasi jika stok 0 atau qty > stok).
    // Tapi karena kita ingin simpel, kita batasi maksimal sejumlah stok yang ada.
    final cartItems = List<CartItemModel>.from(state.cartItems);
    final index = cartItems.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      final currentItem = cartItems[index];
      if (currentItem.quantity < product.stock) {
        cartItems[index] = currentItem.copyWith(quantity: currentItem.quantity + 1);
      } else {
        // Jika sudah mentok stok, jangan tambah
        // Bisa trigger efek UI atau lempar error sementara
        return;
      }
    } else {
      if (product.stock > 0) {
        cartItems.add(CartItemModel(product: product, quantity: 1));
      }
    }

    state = state.copyWith(cartItems: cartItems);
  }

  void decrementQuantity(ProductModel product) {
    final cartItems = List<CartItemModel>.from(state.cartItems);
    final index = cartItems.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      final currentItem = cartItems[index];
      if (currentItem.quantity > 1) {
        cartItems[index] = currentItem.copyWith(quantity: currentItem.quantity - 1);
      } else {
        // Hapus jika qty 1 dikurangi lagi
        cartItems.removeAt(index);
      }
      state = state.copyWith(cartItems: cartItems);
    }
  }

  void removeFromCart(ProductModel product) {
    final cartItems = List<CartItemModel>.from(state.cartItems);
    cartItems.removeWhere((item) => item.product.id == product.id);
    state = state.copyWith(cartItems: cartItems);
  }

  void setQuantity(ProductModel product, int quantity) {
    if (quantity <= 0) {
      removeFromCart(product);
      return;
    }
    
    // Batasi maksimum sesuai stok
    final finalQuantity = quantity > product.stock ? product.stock : quantity;
    
    final cartItems = List<CartItemModel>.from(state.cartItems);
    final index = cartItems.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      cartItems[index] = cartItems[index].copyWith(quantity: finalQuantity);
      state = state.copyWith(cartItems: cartItems);
    } else {
      if (product.stock > 0) {
        cartItems.add(CartItemModel(product: product, quantity: finalQuantity));
        state = state.copyWith(cartItems: cartItems);
      }
    }
  }

  void clearCart() {
    state = state.copyWith(cartItems: []);
  }

  /// Proses checkout kasir.
  Future<bool> checkout({
    required PaymentMethod paymentMethod,
    String? notes,
    String? customerName,
    DateTime? dueDate,
  }) async {
    if (state.cartItems.isEmpty) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final repo = ref.read(transactionRepositoryProvider);
      
      final transactionItems = state.cartItems.map((cartItem) {
        return TransactionItemModel(
          id: '', // Di-generate di repository
          transactionId: '',
          productId: cartItem.product.id,
          productName: cartItem.product.name,
          quantity: cartItem.quantity,
          sellingPriceAtTime: cartItem.product.sellingPrice,
          purchasePriceAtTime: cartItem.product.purchasePrice,
          subtotal: cartItem.subtotal,
        );
      }).toList();

      final transaction = TransactionModel(
        id: '',
        totalAmount: state.totalAmount,
        type: TransactionType.income,
        paymentMethod: paymentMethod,
        notes: notes,
        createdAt: DateTime.now(),
        items: transactionItems,
      );

      final savedTransaction = await repo.saveTransaction(transaction);

      // Jika kasbon, catat piutang
      if (paymentMethod == PaymentMethod.credit && customerName != null && customerName.isNotEmpty) {
        final receivableRepo = ref.read(receivableRepositoryProvider);
        await receivableRepo.insert(
          ReceivableModel(
            id: '',
            transactionId: savedTransaction.id,
            customerName: customerName,
            amount: state.totalAmount,
            paidAmount: 0,
            status: ReceivableStatus.unpaid,
            dueDate: dueDate,
            notes: notes,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      // Refresh data inventaris karena stok berkurang
      ref.invalidate(inventoryProvider);
      
      // Refresh data piutang jika ada penambahan kasbon
      if (paymentMethod == PaymentMethod.credit) {
        ref.invalidate(receivableProvider);
      }

      // Refresh data dashboard & rekap
      ref.invalidate(dashboardProvider);
      ref.invalidate(recapProvider);

      // Kosongkan keranjang setelah berhasil
      state = const PosState();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menyelesaikan transaksi: $e',
      );
      return false;
    }
  }
}

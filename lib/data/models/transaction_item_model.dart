/// Model data untuk item detail dalam satu Transaksi.
///
/// Merepresentasikan satu produk dalam keranjang POS yang sudah disimpan.
/// Menyimpan snapshot harga saat transaksi terjadi (bukan harga produk saat ini),
/// sehingga histori tidak terpengaruh perubahan harga di kemudian hari.
import '../../../core/constants/db_constants.dart';

class TransactionItemModel {
  const TransactionItemModel({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.sellingPriceAtTime,
    required this.purchasePriceAtTime,
    required this.subtotal,
  });

  final String id;
  final String transactionId;
  final String productId;

  /// Nama produk saat transaksi (snapshot, tidak berubah meski produk diedit).
  final String productName;

  final int quantity;

  /// Harga jual saat transaksi dilakukan (snapshot).
  final int sellingPriceAtTime;

  /// Harga beli saat transaksi dilakukan (untuk hitung keuntungan).
  final int purchasePriceAtTime;

  final int subtotal;

  // ─────────────────────────────────────────────────────────────
  // Computed properties
  // ─────────────────────────────────────────────────────────────

  /// Keuntungan dari item ini: (jual - beli) × kuantitas.
  int get profitAmount =>
      (sellingPriceAtTime - purchasePriceAtTime) * quantity;

  // ─────────────────────────────────────────────────────────────
  // Serialization
  // ─────────────────────────────────────────────────────────────

  factory TransactionItemModel.fromMap(Map<String, dynamic> map) {
    return TransactionItemModel(
      id: map[DbConstants.colTxItemId] as String,
      transactionId: map[DbConstants.colTxItemTransactionId] as String,
      productId: map[DbConstants.colTxItemProductId] as String,
      productName: map['product_name'] as String? ?? '',
      quantity: map[DbConstants.colTxItemQuantity] as int,
      sellingPriceAtTime: map[DbConstants.colTxItemSellingPriceAtTime] as int,
      purchasePriceAtTime: map[DbConstants.colTxItemPurchasePriceAtTime] as int,
      subtotal: map[DbConstants.colTxItemSubtotal] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbConstants.colTxItemId: id,
      DbConstants.colTxItemTransactionId: transactionId,
      DbConstants.colTxItemProductId: productId,
      DbConstants.colTxItemQuantity: quantity,
      DbConstants.colTxItemSellingPriceAtTime: sellingPriceAtTime,
      DbConstants.colTxItemPurchasePriceAtTime: purchasePriceAtTime,
      DbConstants.colTxItemSubtotal: subtotal,
    };
  }

  TransactionItemModel copyWith({
    String? id,
    String? transactionId,
    String? productId,
    String? productName,
    int? quantity,
    int? sellingPriceAtTime,
    int? purchasePriceAtTime,
    int? subtotal,
  }) {
    return TransactionItemModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      sellingPriceAtTime: sellingPriceAtTime ?? this.sellingPriceAtTime,
      purchasePriceAtTime: purchasePriceAtTime ?? this.purchasePriceAtTime,
      subtotal: subtotal ?? this.subtotal,
    );
  }

  @override
  String toString() =>
      'TransactionItemModel(product: $productName, qty: $quantity, subtotal: $subtotal)';
}

/// Model data untuk entitas Produk (Inventaris).
///
/// [ProductModel] merepresentasikan satu baris dari tabel `products` di SQLite.
/// Semua operasi konversi dari/ke Map (database) didefinisikan di sini.
import '../../../core/constants/db_constants.dart';

class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stock,
    this.operationalCost = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;

  /// Harga beli produk dalam Rupiah (disimpan sebagai integer, tanpa desimal).
  final int purchasePrice;

  /// Harga jual produk dalam Rupiah.
  final int sellingPrice;

  /// Jumlah stok yang tersedia.
  final int stock;

  /// Biaya operasional per unit (opsional).
  final int operationalCost;

  final DateTime createdAt;
  final DateTime updatedAt;

  // ─────────────────────────────────────────────────────────────
  // Computed properties
  // ─────────────────────────────────────────────────────────────

  /// Keuntungan per unit: harga jual - harga beli - biaya operasional.
  int get profitPerUnit => sellingPrice - purchasePrice - operationalCost;

  /// Margin keuntungan dalam persentase.
  double get profitMarginPercent =>
      purchasePrice > 0 ? (profitPerUnit / purchasePrice) * 100 : 0;

  /// Apakah stok produk ini menipis?
  bool get isLowStock => stock <= 5;

  /// Apakah stok habis?
  bool get isOutOfStock => stock <= 0;

  // ─────────────────────────────────────────────────────────────
  // Serialization
  // ─────────────────────────────────────────────────────────────

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map[DbConstants.colProductId] as String,
      name: map[DbConstants.colProductName] as String,
      purchasePrice: map[DbConstants.colProductPurchasePrice] as int,
      sellingPrice: map[DbConstants.colProductSellingPrice] as int,
      stock: map[DbConstants.colProductStock] as int,
      operationalCost: map[DbConstants.colProductOperationalCost] as int? ?? 0,
      createdAt: DateTime.parse(map[DbConstants.colProductCreatedAt] as String),
      updatedAt: DateTime.parse(map[DbConstants.colProductUpdatedAt] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbConstants.colProductId: id,
      DbConstants.colProductName: name,
      DbConstants.colProductPurchasePrice: purchasePrice,
      DbConstants.colProductSellingPrice: sellingPrice,
      DbConstants.colProductStock: stock,
      DbConstants.colProductOperationalCost: operationalCost,
      DbConstants.colProductCreatedAt: createdAt.toIso8601String(),
      DbConstants.colProductUpdatedAt: updatedAt.toIso8601String(),
    };
  }

  /// Buat salinan dengan field yang diubah (immutable update).
  ProductModel copyWith({
    String? id,
    String? name,
    int? purchasePrice,
    int? sellingPrice,
    int? stock,
    int? operationalCost,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stock: stock ?? this.stock,
      operationalCost: operationalCost ?? this.operationalCost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'ProductModel(id: $id, name: $name, stock: $stock, sellingPrice: $sellingPrice)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

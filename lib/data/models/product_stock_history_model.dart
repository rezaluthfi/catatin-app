import '../../../core/constants/db_constants.dart';

class ProductStockHistoryModel {
  final String id;
  final String productId;
  final int purchasePrice;
  final int sellingPrice;
  final int stockAdded;
  final DateTime date;
  final DateTime createdAt;

  ProductStockHistoryModel({
    required this.id,
    required this.productId,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stockAdded,
    required this.date,
    required this.createdAt,
  });

  factory ProductStockHistoryModel.fromMap(Map<String, dynamic> map) {
    return ProductStockHistoryModel(
      id: map[DbConstants.colHistoryId] as String,
      productId: map[DbConstants.colHistoryProductId] as String,
      purchasePrice: map[DbConstants.colHistoryPurchasePrice] as int,
      sellingPrice: map[DbConstants.colHistorySellingPrice] as int,
      stockAdded: map[DbConstants.colHistoryStockAdded] as int,
      date: DateTime.parse(map[DbConstants.colHistoryDate] as String),
      createdAt: DateTime.parse(map[DbConstants.colHistoryCreatedAt] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbConstants.colHistoryId: id,
      DbConstants.colHistoryProductId: productId,
      DbConstants.colHistoryPurchasePrice: purchasePrice,
      DbConstants.colHistorySellingPrice: sellingPrice,
      DbConstants.colHistoryStockAdded: stockAdded,
      DbConstants.colHistoryDate: date.toIso8601String().substring(0, 10), // YYYY-MM-DD
      DbConstants.colHistoryCreatedAt: createdAt.toIso8601String(),
    };
  }

  ProductStockHistoryModel copyWith({
    String? id,
    String? productId,
    int? purchasePrice,
    int? sellingPrice,
    int? stockAdded,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return ProductStockHistoryModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockAdded: stockAdded ?? this.stockAdded,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

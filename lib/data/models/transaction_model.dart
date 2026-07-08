/// Model data untuk header Transaksi.
///
/// Satu [TransactionModel] merepresentasikan satu transaksi penjualan (header),
/// yang terhubung ke banyak [TransactionItemModel] (detail per produk).
import '../../../core/constants/db_constants.dart';
import 'transaction_enums.dart';
import 'transaction_item_model.dart';

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.totalAmount,
    required this.type,
    required this.paymentMethod,
    this.notes,
    required this.createdAt,
    this.items = const [],
  });

  final String id;
  final int totalAmount;
  final TransactionType type;
  final PaymentMethod paymentMethod;
  final String? notes;
  final DateTime createdAt;

  /// Item-item dalam transaksi ini (di-load via JOIN atau query terpisah).
  final List<TransactionItemModel> items;

  // ─────────────────────────────────────────────────────────────
  // Computed properties
  // ─────────────────────────────────────────────────────────────

  /// Apakah transaksi ini menggunakan kasbon?
  bool get isCredit => paymentMethod == PaymentMethod.credit;

  /// Total keuntungan kotor dari semua item dalam transaksi.
  int get totalProfit => items.fold(
        0,
        (sum, item) => sum + item.profitAmount,
      );

  // ─────────────────────────────────────────────────────────────
  // Serialization
  // ─────────────────────────────────────────────────────────────

  factory TransactionModel.fromMap(
    Map<String, dynamic> map, {
    List<TransactionItemModel> items = const [],
  }) {
    return TransactionModel(
      id: map[DbConstants.colTransactionId] as String,
      totalAmount: map[DbConstants.colTransactionTotalAmount] as int,
      type: TransactionType.fromString(
        map[DbConstants.colTransactionType] as String,
      ),
      paymentMethod: PaymentMethod.fromString(
        map[DbConstants.colTransactionPaymentMethod] as String,
      ),
      notes: map[DbConstants.colTransactionNotes] as String?,
      createdAt: DateTime.parse(
        map[DbConstants.colTransactionCreatedAt] as String,
      ),
      items: items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbConstants.colTransactionId: id,
      DbConstants.colTransactionTotalAmount: totalAmount,
      DbConstants.colTransactionType: type.value,
      DbConstants.colTransactionPaymentMethod: paymentMethod.value,
      DbConstants.colTransactionNotes: notes,
      DbConstants.colTransactionCreatedAt: createdAt.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    String? id,
    int? totalAmount,
    TransactionType? type,
    PaymentMethod? paymentMethod,
    String? notes,
    DateTime? createdAt,
    List<TransactionItemModel>? items,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      totalAmount: totalAmount ?? this.totalAmount,
      type: type ?? this.type,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  @override
  String toString() =>
      'TransactionModel(id: $id, total: $totalAmount, method: ${paymentMethod.label})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Model data untuk Biaya Operasional.
///
/// Mencatat pengeluaran di luar pembelian stok, misalnya biaya listrik,
/// sewa tempat, atau biaya operasional lainnya.
import '../../../core/constants/db_constants.dart';

class OperationalCostModel {
  const OperationalCostModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.createdAt,
  });

  final String id;
  final String description;
  final int amount;
  final DateTime date;
  final DateTime createdAt;

  // ─────────────────────────────────────────────────────────────
  // Serialization
  // ─────────────────────────────────────────────────────────────

  factory OperationalCostModel.fromMap(Map<String, dynamic> map) {
    return OperationalCostModel(
      id: map[DbConstants.colCostId] as String,
      description: map[DbConstants.colCostDescription] as String,
      amount: map[DbConstants.colCostAmount] as int,
      date: DateTime.parse(map[DbConstants.colCostDate] as String),
      createdAt: DateTime.parse(map[DbConstants.colCostCreatedAt] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbConstants.colCostId: id,
      DbConstants.colCostDescription: description,
      DbConstants.colCostAmount: amount,
      DbConstants.colCostDate: date.toIso8601String(),
      DbConstants.colCostCreatedAt: createdAt.toIso8601String(),
    };
  }

  OperationalCostModel copyWith({
    String? id,
    String? description,
    int? amount,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return OperationalCostModel(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'OperationalCostModel(description: $description, amount: $amount, date: $date)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OperationalCostModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

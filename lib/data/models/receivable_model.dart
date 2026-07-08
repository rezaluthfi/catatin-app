// Model data untuk Piutang Pelanggan (Kasbon).
//
// Bisa dibuat otomatis dari transaksi POS (dengan [transactionId])
// atau dibuat manual tanpa transaksi terkait ([transactionId] = null).
import '../../../core/constants/db_constants.dart';

/// Enum untuk status piutang.
enum ReceivableStatus {
  unpaid('unpaid'),   // Belum dibayar sama sekali
  partial('partial'), // Baru bayar sebagian
  paid('paid');       // Lunas

  const ReceivableStatus(this.value);
  final String value;

  String get label => switch (this) {
        ReceivableStatus.unpaid => 'Belum Lunas',
        ReceivableStatus.partial => 'Bayar Sebagian',
        ReceivableStatus.paid => 'Lunas',
      };

  static ReceivableStatus fromString(String value) {
    return ReceivableStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReceivableStatus.unpaid,
    );
  }
}

class ReceivableModel {
  const ReceivableModel({
    required this.id,
    this.transactionId,
    required this.customerName,
    required this.amount,
    this.paidAmount = 0,
    required this.status,
    this.notes,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// Nullable: kosong jika piutang diinput manual (bukan dari POS).
  final String? transactionId;

  final String customerName;

  /// Total jumlah yang harus dibayar.
  final int amount;

  /// Jumlah yang sudah dibayar (untuk cicilan).
  final int paidAmount;

  final ReceivableStatus status;
  final String? notes;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─────────────────────────────────────────────────────────────
  // Computed properties
  // ─────────────────────────────────────────────────────────────

  /// Jumlah yang masih belum dibayar.
  int get remainingAmount => amount - paidAmount;

  /// Apakah piutang ini berasal dari transaksi POS?
  bool get isFromTransaction => transactionId != null;

  /// Apakah piutang ini sudah lunas?
  bool get isPaid => status == ReceivableStatus.paid;

  // ─────────────────────────────────────────────────────────────
  // Serialization
  // ─────────────────────────────────────────────────────────────

  factory ReceivableModel.fromMap(Map<String, dynamic> map) {
    return ReceivableModel(
      id: map[DbConstants.colReceivableId] as String,
      transactionId: map[DbConstants.colReceivableTransactionId] as String?,
      customerName: map[DbConstants.colReceivableCustomerName] as String,
      amount: map[DbConstants.colReceivableAmount] as int,
      paidAmount: map[DbConstants.colReceivablePaidAmount] as int? ?? 0,
      status: ReceivableStatus.fromString(
        map[DbConstants.colReceivableStatus] as String,
      ),
      notes: map[DbConstants.colReceivableNotes] as String?,
      dueDate: map[DbConstants.colReceivableDueDate] != null
          ? DateTime.parse(map[DbConstants.colReceivableDueDate] as String)
          : null,
      createdAt: DateTime.parse(
        map[DbConstants.colReceivableCreatedAt] as String,
      ),
      updatedAt: DateTime.parse(
        map[DbConstants.colReceivableUpdatedAt] as String,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbConstants.colReceivableId: id,
      DbConstants.colReceivableTransactionId: transactionId,
      DbConstants.colReceivableCustomerName: customerName,
      DbConstants.colReceivableAmount: amount,
      DbConstants.colReceivablePaidAmount: paidAmount,
      DbConstants.colReceivableStatus: status.value,
      DbConstants.colReceivableNotes: notes,
      DbConstants.colReceivableDueDate: dueDate?.toIso8601String(),
      DbConstants.colReceivableCreatedAt: createdAt.toIso8601String(),
      DbConstants.colReceivableUpdatedAt: updatedAt.toIso8601String(),
    };
  }

  ReceivableModel copyWith({
    String? id,
    String? transactionId,
    String? customerName,
    int? amount,
    int? paidAmount,
    ReceivableStatus? status,
    String? notes,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReceivableModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'ReceivableModel(customer: $customerName, amount: $amount, status: ${status.label})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceivableModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

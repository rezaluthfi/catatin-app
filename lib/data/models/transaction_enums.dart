/// Enum untuk jenis transaksi.
enum TransactionType {
  income('income'),   // Kas masuk (penjualan)
  expense('expense'); // Kas keluar (pembelian stok, dll.)

  const TransactionType(this.value);
  final String value;

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransactionType.income,
    );
  }
}

/// Enum untuk metode pembayaran.
enum PaymentMethod {
  cash('cash'),     // Tunai
  credit('credit'); // Kasbon (piutang)

  const PaymentMethod(this.value);
  final String value;

  /// Label tampilan dalam Bahasa Indonesia.
  String get label => switch (this) {
        PaymentMethod.cash => 'Tunai',
        PaymentMethod.credit => 'Kasbon',
      };

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

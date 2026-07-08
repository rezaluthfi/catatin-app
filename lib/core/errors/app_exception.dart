// Custom exception classes untuk aplikasi Catatin.
//
// Menggunakan hierarki exception spesifik agar error handling
// di layer atas (provider/UI) dapat membedakan jenis kesalahan
// dan menampilkan pesan yang sesuai kepada pengguna.

/// Base class untuk semua exception di aplikasi Catatin.
class AppException implements Exception {
  const AppException(this.message, {this.originalError});

  final String message;
  final Object? originalError;

  @override
  String toString() => 'AppException: $message';
}

/// Exception untuk kegagalan operasi database.
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.originalError});

  @override
  String toString() => 'DatabaseException: $message';
}

/// Exception untuk kegagalan validasi input.
class ValidationException extends AppException {
  const ValidationException(super.message);

  @override
  String toString() => 'ValidationException: $message';
}

/// Exception untuk PIN yang tidak valid atau tidak cocok.
class InvalidPinException extends AppException {
  const InvalidPinException([String message = 'PIN tidak valid'])
      : super(message);

  @override
  String toString() => 'InvalidPinException: $message';
}

/// Exception ketika data yang dicari tidak ditemukan.
class NotFoundException extends AppException {
  const NotFoundException([String message = 'Data tidak ditemukan'])
      : super(message);

  @override
  String toString() => 'NotFoundException: $message';
}

/// Exception untuk operasi export/import file yang gagal.
class FileOperationException extends AppException {
  const FileOperationException(super.message, {super.originalError});

  @override
  String toString() => 'FileOperationException: $message';
}

/// Exception ketika stok produk tidak mencukupi untuk transaksi.
class InsufficientStockException extends AppException {
  InsufficientStockException(String productName, int available)
      : super('Stok "$productName" tidak mencukupi. Tersedia: $available');

  @override
  String toString() => 'InsufficientStockException: $message';
}

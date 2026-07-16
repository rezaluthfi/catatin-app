/// Interface (kontrak) untuk repository Produk.
///
/// Mendefinisikan operasi apa saja yang bisa dilakukan terhadap data produk,
/// tanpa menyebutkan implementasi konkretnya (SQLite, mock, dll.).
/// Ini memungkinkan testing dengan mock repository tanpa menyentuh database asli.
import '../../data/models/product_model.dart';
import '../../data/models/product_stock_history_model.dart';

abstract interface class IProductRepository {
  /// Ambil semua produk, diurutkan berdasarkan nama secara ascending.
  Future<List<ProductModel>> getAll();

  /// Ambil produk berdasarkan ID. Kembalikan null jika tidak ditemukan.
  Future<ProductModel?> getById(String id);

  /// Tambah produk baru. Kembalikan produk yang sudah tersimpan.
  Future<ProductModel> insert(ProductModel product);

  /// Update data produk yang sudah ada.
  Future<void> update(ProductModel product);

  /// Hapus produk berdasarkan ID.
  Future<void> delete(String id);

  /// Kurangi stok produk setelah transaksi. Digunakan oleh POS.
  Future<void> decreaseStock(String productId, int quantity);

  /// Ambil daftar produk dengan stok menipis (stok ≤ threshold).
  Future<List<ProductModel>> getLowStockProducts({int threshold = 5});

  /// Cari produk berdasarkan nama (case-insensitive).
  Future<List<ProductModel>> search(String query);

  /// Ambil riwayat penambahan stok produk.
  Future<List<ProductStockHistoryModel>> getStockHistory(String productId);

  /// Masukkan catatan riwayat stok baru.
  Future<void> insertStockHistory(ProductStockHistoryModel history);
}

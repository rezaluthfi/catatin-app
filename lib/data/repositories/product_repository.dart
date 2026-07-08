/// Implementasi konkret [IProductRepository] menggunakan SQLite via [DatabaseHelper].
import 'package:uuid/uuid.dart';

import '../../core/constants/db_constants.dart';
import '../../core/database/database_helper.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../models/product_model.dart';

class ProductRepository implements IProductRepository {
  ProductRepository({DatabaseHelper? dbHelper})
      : _db = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _db;
  final _uuid = const Uuid();

  @override
  Future<List<ProductModel>> getAll() async {
    try {
      final rows = await _db.queryAll(
        DbConstants.tableProducts,
        orderBy: '${DbConstants.colProductName} ASC',
      );
      return rows.map(ProductModel.fromMap).toList();
    } catch (e) {
      throw DatabaseException('Gagal mengambil data produk', originalError: e);
    }
  }

  @override
  Future<ProductModel?> getById(String id) async {
    try {
      final rows = await _db.queryAll(
        DbConstants.tableProducts,
        where: '${DbConstants.colProductId} = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return ProductModel.fromMap(rows.first);
    } catch (e) {
      throw DatabaseException('Gagal mengambil produk dengan ID: $id',
          originalError: e);
    }
  }

  @override
  Future<ProductModel> insert(ProductModel product) async {
    try {
      final now = DateTime.now();
      final newProduct = product.copyWith(
        id: _uuid.v4(),
        createdAt: now,
        updatedAt: now,
      );
      await _db.insert(DbConstants.tableProducts, newProduct.toMap());
      return newProduct;
    } catch (e) {
      throw DatabaseException('Gagal menambah produk', originalError: e);
    }
  }

  @override
  Future<void> update(ProductModel product) async {
    try {
      final updated = product.copyWith(updatedAt: DateTime.now());
      await _db.update(
        DbConstants.tableProducts,
        updated.toMap(),
        where: '${DbConstants.colProductId} = ?',
        whereArgs: [product.id],
      );
    } catch (e) {
      throw DatabaseException('Gagal mengupdate produk', originalError: e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _db.delete(
        DbConstants.tableProducts,
        where: '${DbConstants.colProductId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Gagal menghapus produk', originalError: e);
    }
  }

  @override
  Future<void> decreaseStock(String productId, int quantity) async {
    try {
      // Cek stok tersedia terlebih dahulu
      final product = await getById(productId);
      if (product == null) throw NotFoundException('Produk tidak ditemukan');
      if (product.stock < quantity) {
        throw InsufficientStockException(product.name, product.stock);
      }

      await _db.rawExecute(
        '''UPDATE ${DbConstants.tableProducts}
           SET ${DbConstants.colProductStock} = ${DbConstants.colProductStock} - ?,
               ${DbConstants.colProductUpdatedAt} = ?
           WHERE ${DbConstants.colProductId} = ?''',
        [quantity, DateTime.now().toIso8601String(), productId],
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Gagal mengurangi stok produk', originalError: e);
    }
  }

  @override
  Future<List<ProductModel>> getLowStockProducts({int threshold = 5}) async {
    try {
      final rows = await _db.queryAll(
        DbConstants.tableProducts,
        where: '${DbConstants.colProductStock} <= ?',
        whereArgs: [threshold],
        orderBy: '${DbConstants.colProductStock} ASC',
      );
      return rows.map(ProductModel.fromMap).toList();
    } catch (e) {
      throw DatabaseException('Gagal mengambil produk stok menipis',
          originalError: e);
    }
  }

  @override
  Future<List<ProductModel>> search(String query) async {
    try {
      final rows = await _db.queryAll(
        DbConstants.tableProducts,
        where: '${DbConstants.colProductName} LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: '${DbConstants.colProductName} ASC',
      );
      return rows.map(ProductModel.fromMap).toList();
    } catch (e) {
      throw DatabaseException('Gagal mencari produk', originalError: e);
    }
  }
}

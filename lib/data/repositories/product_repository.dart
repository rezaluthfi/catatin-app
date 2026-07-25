/// Implementasi konkret [IProductRepository] menggunakan SQLite via [DatabaseHelper].
import 'package:uuid/uuid.dart';

import '../../core/constants/db_constants.dart';
import '../../core/database/database_helper.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../models/product_model.dart';
import '../models/product_stock_history_model.dart';

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

  Future<ProductModel?> getByName(String name) async {
    try {
      final rows = await _db.queryAll(
        DbConstants.tableProducts,
        where: 'LOWER(${DbConstants.colProductName}) = ?',
        whereArgs: [name.trim().toLowerCase()],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return ProductModel.fromMap(rows.first);
    } catch (e) {
      throw DatabaseException('Gagal mengambil produk berdasarkan nama: $name',
          originalError: e);
    }
  }

  @override
  Future<ProductModel> insert(ProductModel product) async {
    try {
      final existing = await getByName(product.name);
      if (existing != null) {
        // Gabungkan (Merge) stok jika produk dengan nama yang sama sudah ada
        final updatedStock = existing.stock + product.stock;
        final updatedProduct = existing.copyWith(
          stock: updatedStock,
          purchasePrice: product.purchasePrice,
          sellingPrice: product.sellingPrice,
          imagePath: () => product.imagePath ?? existing.imagePath,
          updatedAt: DateTime.now(),
        );
        
        await _db.update(
          DbConstants.tableProducts,
          updatedProduct.toMap(),
          where: '${DbConstants.colProductId} = ?',
          whereArgs: [existing.id],
        );

        // Catat riwayat penambahan stok
        final history = ProductStockHistoryModel(
          id: _uuid.v4(),
          productId: existing.id,
          purchasePrice: product.purchasePrice,
          sellingPrice: product.sellingPrice,
          stockAdded: product.stock,
          date: product.createdAt, // Tanggal masuk stok dari user
          createdAt: DateTime.now(),
        );
        await insertStockHistory(history);

        return updatedProduct;
      } else {
        // Masukkan produk baru secara normal
        final newId = _uuid.v4();
        final newProduct = product.copyWith(
          id: newId,
        );
        await _db.insert(DbConstants.tableProducts, newProduct.toMap());

        // Catat riwayat stok awal
        final history = ProductStockHistoryModel(
          id: _uuid.v4(),
          productId: newId,
          purchasePrice: product.purchasePrice,
          sellingPrice: product.sellingPrice,
          stockAdded: product.stock,
          date: product.createdAt, // Tanggal masuk stok dari user
          createdAt: DateTime.now(),
        );
        await insertStockHistory(history);

        return newProduct;
      }
    } catch (e) {
      throw DatabaseException('Gagal menambah produk', originalError: e);
    }
  }

  @override
  Future<void> update(ProductModel product) async {
    try {
      final oldProduct = await getById(product.id);
      
      await _db.update(
        DbConstants.tableProducts,
        product.toMap(),
        where: '${DbConstants.colProductId} = ?',
        whereArgs: [product.id],
      );

      // Jika ada perubahan stok, catat riwayatnya
      if (oldProduct != null && oldProduct.stock != product.stock) {
        final diff = product.stock - oldProduct.stock;
        final history = ProductStockHistoryModel(
          id: _uuid.v4(),
          productId: product.id,
          purchasePrice: product.purchasePrice,
          sellingPrice: product.sellingPrice,
          stockAdded: diff,
          date: product.updatedAt, // Tanggal perubahan stok
          createdAt: DateTime.now(),
        );
        await insertStockHistory(history);
      }
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
  Future<List<ProductStockHistoryModel>> getStockHistory(String productId) async {
    try {
      final rows = await _db.queryAll(
        DbConstants.tableProductStockHistory,
        where: '${DbConstants.colHistoryProductId} = ?',
        whereArgs: [productId],
        orderBy: '${DbConstants.colHistoryDate} DESC, ${DbConstants.colHistoryCreatedAt} DESC',
      );
      final historyList = rows.map(ProductStockHistoryModel.fromMap).toList();

      // Ambil transaksi POS yang menyertakan produk ini untuk riwayat stok lengkap
      final txRows = await _db.rawQuery(
        '''SELECT ti.${DbConstants.colTxItemId} as item_id,
                  ti.${DbConstants.colTxItemProductId} as product_id,
                  ti.${DbConstants.colTxItemPurchasePriceAtTime} as purchase_price,
                  ti.${DbConstants.colTxItemSellingPriceAtTime} as selling_price,
                  ti.${DbConstants.colTxItemQuantity} as quantity,
                  t.${DbConstants.colTransactionCreatedAt} as created_at
           FROM ${DbConstants.tableTransactionItems} ti
           JOIN ${DbConstants.tableTransactions} t ON ti.${DbConstants.colTxItemTransactionId} = t.${DbConstants.colTransactionId}
           WHERE ti.${DbConstants.colTxItemProductId} = ?''',
        [productId],
      );

      for (final txRow in txRows) {
        final itemId = txRow['item_id'] as String;
        final posId = 'pos_$itemId';
        final qty = -(txRow['quantity'] as int);
        final txDate = DateTime.parse(txRow['created_at'] as String);

        final isAlreadyPresent = historyList.any((h) {
          if (h.id == posId || h.id == itemId) return true;
          if (h.id.startsWith('pos_') &&
              h.stockAdded == qty &&
              h.createdAt.difference(txDate).inSeconds.abs() <= 5) {
            return true;
          }
          return false;
        });

        if (!isAlreadyPresent) {
          historyList.add(
            ProductStockHistoryModel(
              id: posId,
              productId: productId,
              purchasePrice: txRow['purchase_price'] as int,
              sellingPrice: txRow['selling_price'] as int,
              stockAdded: qty,
              date: txDate,
              createdAt: txDate,
            ),
          );
        }
      }

      historyList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return historyList;
    } catch (e) {
      throw DatabaseException('Gagal mengambil riwayat stok produk', originalError: e);
    }
  }

  @override
  Future<void> insertStockHistory(ProductStockHistoryModel history) async {
    try {
      await _db.insert(DbConstants.tableProductStockHistory, history.toMap());
    } catch (e) {
      throw DatabaseException('Gagal menyimpan riwayat stok produk', originalError: e);
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/product_repository.dart';
import '../../data/repositories/receivable_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../../domain/repositories/i_receivable_repository.dart';
import '../../domain/repositories/i_transaction_repository.dart';

/// Provider untuk instance [IProductRepository].
/// Karena SQLite (DatabaseHelper) dikelola secara singleton atau diakses langsung,
/// provider ini bisa dibuat secara synchronous (Provider biasa).
final productRepositoryProvider = Provider<IProductRepository>((ref) {
  return ProductRepository();
});

/// Provider untuk instance [ITransactionRepository].
final transactionRepositoryProvider = Provider<ITransactionRepository>((ref) {
  return TransactionRepository();
});

/// Provider untuk instance [IReceivableRepository].
final receivableRepositoryProvider = Provider<IReceivableRepository>((ref) {
  return ReceivableRepository();
});

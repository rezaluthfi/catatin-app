/// Konstanta nama tabel dan kolom database SQLite.
///
/// Mendefinisikan semua nama tabel dan kolom sebagai konstanta
/// untuk menghindari typo dan memudahkan perubahan skema di masa depan.
class DbConstants {
  DbConstants._(); // Prevent instantiation

  // --- Database ---
  static const String dbName = 'catatin.db';
  static const int dbVersion = 2;

  // ─────────────────────────────────────────────────────────────
  // Tabel: products
  // ─────────────────────────────────────────────────────────────
  static const String tableProducts = 'products';
  static const String colProductId = 'id';
  static const String colProductName = 'name';
  static const String colProductPurchasePrice = 'purchase_price';
  static const String colProductSellingPrice = 'selling_price';
  static const String colProductStock = 'stock';
  static const String colProductOperationalCost = 'operational_cost';
  static const String colProductImagePath = 'image_path';
  static const String colProductCreatedAt = 'created_at';
  static const String colProductUpdatedAt = 'updated_at';

  // ─────────────────────────────────────────────────────────────
  // Tabel: product_stock_history
  // ─────────────────────────────────────────────────────────────
  static const String tableProductStockHistory = 'product_stock_history';
  static const String colHistoryId = 'id';
  static const String colHistoryProductId = 'product_id';
  static const String colHistoryPurchasePrice = 'purchase_price';
  static const String colHistorySellingPrice = 'selling_price';
  static const String colHistoryStockAdded = 'stock_added';
  static const String colHistoryDate = 'date';
  static const String colHistoryCreatedAt = 'created_at';

  // ─────────────────────────────────────────────────────────────
  // Tabel: transactions
  // ─────────────────────────────────────────────────────────────
  static const String tableTransactions = 'transactions';
  static const String colTransactionId = 'id';
  static const String colTransactionTotalAmount = 'total_amount';
  static const String colTransactionType = 'type'; // 'income' | 'expense'
  static const String colTransactionPaymentMethod = 'payment_method'; // 'cash' | 'credit'
  static const String colTransactionNotes = 'notes';
  static const String colTransactionCreatedAt = 'created_at';

  // ─────────────────────────────────────────────────────────────
  // Tabel: transaction_items
  // ─────────────────────────────────────────────────────────────
  static const String tableTransactionItems = 'transaction_items';
  static const String colTxItemId = 'id';
  static const String colTxItemTransactionId = 'transaction_id';
  static const String colTxItemProductId = 'product_id';
  static const String colTxItemQuantity = 'quantity';
  static const String colTxItemSellingPriceAtTime = 'selling_price_at_time';
  static const String colTxItemPurchasePriceAtTime = 'purchase_price_at_time';
  static const String colTxItemSubtotal = 'subtotal';

  // ─────────────────────────────────────────────────────────────
  // Tabel: receivables
  // ─────────────────────────────────────────────────────────────
  static const String tableReceivables = 'receivables';
  static const String colReceivableId = 'id';
  static const String colReceivableTransactionId = 'transaction_id'; // nullable
  static const String colReceivableCustomerName = 'customer_name';
  static const String colReceivableAmount = 'amount';
  static const String colReceivablePaidAmount = 'paid_amount';
  static const String colReceivableStatus = 'status'; // 'unpaid' | 'partial' | 'paid'
  static const String colReceivableNotes = 'notes';
  static const String colReceivableDueDate = 'due_date';
  static const String colReceivableCreatedAt = 'created_at';
  static const String colReceivableUpdatedAt = 'updated_at';

  // ─────────────────────────────────────────────────────────────
  // Tabel: operational_costs
  // ─────────────────────────────────────────────────────────────
  static const String tableOperationalCosts = 'operational_costs';
  static const String colCostId = 'id';
  static const String colCostDescription = 'description';
  static const String colCostAmount = 'amount';
  static const String colCostDate = 'date';
  static const String colCostCreatedAt = 'created_at';

  // ─────────────────────────────────────────────────────────────
  // Tabel: settings
  // ─────────────────────────────────────────────────────────────
  static const String tableSettings = 'settings';
  static const String colSettingKey = 'key';
  static const String colSettingValue = 'value';
}

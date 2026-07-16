/// Skema SQL untuk inisialisasi dan migrasi database Catatin.
///
/// Semua DDL (CREATE TABLE) didefinisikan di sini sebagai konstanta String
/// agar mudah di-review dan diubah tanpa harus menyentuh DatabaseHelper.
import '../constants/db_constants.dart';

class AppDatabase {
  AppDatabase._(); // Prevent instantiation

  /// Script SQL untuk membuat semua tabel saat database pertama kali dibuat.
  static const List<String> createTableScripts = [
    _createProductsTable,
    _createTransactionsTable,
    _createTransactionItemsTable,
    _createReceivablesTable,
    _createOperationalCostsTable,
    _createSettingsTable,
    _createProductStockHistoryTable,
    _createIndexScripts,
  ];

  // ─────────────────────────────────────────────────────────────
  // CREATE TABLE scripts
  // ─────────────────────────────────────────────────────────────

  static const String _createProductsTable = '''
    CREATE TABLE ${DbConstants.tableProducts} (
      ${DbConstants.colProductId}               TEXT PRIMARY KEY,
      ${DbConstants.colProductName}             TEXT NOT NULL,
      ${DbConstants.colProductPurchasePrice}    INTEGER NOT NULL DEFAULT 0,
      ${DbConstants.colProductSellingPrice}     INTEGER NOT NULL DEFAULT 0,
      ${DbConstants.colProductStock}            INTEGER NOT NULL DEFAULT 0,
      ${DbConstants.colProductOperationalCost}  INTEGER NOT NULL DEFAULT 0,
      ${DbConstants.colProductImagePath}        TEXT,
      ${DbConstants.colProductCreatedAt}        TEXT NOT NULL,
      ${DbConstants.colProductUpdatedAt}        TEXT NOT NULL
    )
  ''';

  static const String createProductStockHistoryTableScript = _createProductStockHistoryTable;

  static const String _createProductStockHistoryTable = '''
    CREATE TABLE ${DbConstants.tableProductStockHistory} (
      ${DbConstants.colHistoryId}             TEXT PRIMARY KEY,
      ${DbConstants.colHistoryProductId}      TEXT NOT NULL,
      ${DbConstants.colHistoryPurchasePrice}   INTEGER NOT NULL DEFAULT 0,
      ${DbConstants.colHistorySellingPrice}    INTEGER NOT NULL DEFAULT 0,
      ${DbConstants.colHistoryStockAdded}      INTEGER NOT NULL DEFAULT 0,
      ${DbConstants.colHistoryDate}            TEXT NOT NULL,
      ${DbConstants.colHistoryCreatedAt}       TEXT NOT NULL,
      FOREIGN KEY (${DbConstants.colHistoryProductId})
        REFERENCES ${DbConstants.tableProducts}(${DbConstants.colProductId})
        ON DELETE CASCADE
    )
  ''';

  static const String _createTransactionsTable = '''
    CREATE TABLE ${DbConstants.tableTransactions} (
      ${DbConstants.colTransactionId}            TEXT PRIMARY KEY,
      ${DbConstants.colTransactionTotalAmount}   INTEGER NOT NULL DEFAULT 0,
      ${DbConstants.colTransactionType}          TEXT NOT NULL,
      ${DbConstants.colTransactionPaymentMethod} TEXT NOT NULL,
      ${DbConstants.colTransactionNotes}         TEXT,
      ${DbConstants.colTransactionCreatedAt}     TEXT NOT NULL
    )
  ''';

  static const String _createTransactionItemsTable = '''
    CREATE TABLE ${DbConstants.tableTransactionItems} (
      ${DbConstants.colTxItemId}                 TEXT PRIMARY KEY,
      ${DbConstants.colTxItemTransactionId}      TEXT NOT NULL,
      ${DbConstants.colTxItemProductId}          TEXT NOT NULL,
      ${DbConstants.colTxItemQuantity}           INTEGER NOT NULL DEFAULT 1,
      ${DbConstants.colTxItemSellingPriceAtTime} INTEGER NOT NULL DEFAULT 0,
      ${DbConstants.colTxItemPurchasePriceAtTime} INTEGER NOT NULL DEFAULT 0,
      ${DbConstants.colTxItemSubtotal}           INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (${DbConstants.colTxItemTransactionId})
        REFERENCES ${DbConstants.tableTransactions}(${DbConstants.colTransactionId})
        ON DELETE CASCADE
    )
  ''';

  static const String _createReceivablesTable = '''
    CREATE TABLE ${DbConstants.tableReceivables} (
      ${DbConstants.colReceivableId}             TEXT PRIMARY KEY,
      ${DbConstants.colReceivableTransactionId}  TEXT,
      ${DbConstants.colReceivableCustomerName}   TEXT NOT NULL,
      ${DbConstants.colReceivableAmount}         INTEGER NOT NULL DEFAULT 0,
      ${DbConstants.colReceivablePaidAmount}     INTEGER NOT NULL DEFAULT 0,
      ${DbConstants.colReceivableStatus}         TEXT NOT NULL DEFAULT 'unpaid',
      ${DbConstants.colReceivableNotes}          TEXT,
      ${DbConstants.colReceivableDueDate}        TEXT,
      ${DbConstants.colReceivableCreatedAt}      TEXT NOT NULL,
      ${DbConstants.colReceivableUpdatedAt}      TEXT NOT NULL,
      FOREIGN KEY (${DbConstants.colReceivableTransactionId})
        REFERENCES ${DbConstants.tableTransactions}(${DbConstants.colTransactionId})
        ON DELETE SET NULL
    )
  ''';

  static const String _createOperationalCostsTable = '''
    CREATE TABLE ${DbConstants.tableOperationalCosts} (
      ${DbConstants.colCostId}          TEXT PRIMARY KEY,
      ${DbConstants.colCostDescription} TEXT NOT NULL,
      ${DbConstants.colCostAmount}      INTEGER NOT NULL DEFAULT 0,
      ${DbConstants.colCostDate}        TEXT NOT NULL,
      ${DbConstants.colCostCreatedAt}   TEXT NOT NULL
    )
  ''';

  static const String _createSettingsTable = '''
    CREATE TABLE ${DbConstants.tableSettings} (
      ${DbConstants.colSettingKey}   TEXT PRIMARY KEY,
      ${DbConstants.colSettingValue} TEXT NOT NULL
    )
  ''';

  /// Index untuk mempercepat query berdasarkan tanggal (sering dipakai di rekapitulasi).
  static const String _createIndexScripts = '''
    CREATE INDEX IF NOT EXISTS idx_transactions_created_at
      ON ${DbConstants.tableTransactions}(${DbConstants.colTransactionCreatedAt});
    CREATE INDEX IF NOT EXISTS idx_operational_costs_date
      ON ${DbConstants.tableOperationalCosts}(${DbConstants.colCostDate});
    CREATE INDEX IF NOT EXISTS idx_receivables_status
      ON ${DbConstants.tableReceivables}(${DbConstants.colReceivableStatus})
  ''';
}

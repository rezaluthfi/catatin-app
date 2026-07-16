// Singleton helper untuk mengelola koneksi database SQLite.
// Menggunakan pola Singleton agar hanya ada satu instance koneksi database
// di seluruh siklus hidup aplikasi, mencegah konflik akses concurrent.
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;

import '../constants/db_constants.dart';
import 'app_database.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  /// Instance Singleton — gunakan [DatabaseHelper.instance] untuk akses.
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  /// Mengembalikan instance database. Membuat database baru jika belum ada.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Inisialisasi database — dipanggil sekali saat pertama kali diakses.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DbConstants.dbName);

    return await openDatabase(
      path,
      version: DbConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      // Aktifkan foreign key support
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  /// Dipanggil saat database pertama kali dibuat.
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    for (final script in AppDatabase.createTableScripts) {
      batch.execute(script);
    }
    await batch.commit(noResult: true);
  }

  /// Dipanggil saat versi database naik (migrasi skema).
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE ${DbConstants.tableProducts} ADD COLUMN ${DbConstants.colProductImagePath} TEXT',
      );
      await db.execute(AppDatabase.createProductStockHistoryTableScript);
    }
  }

  /// Menutup koneksi database (gunakan saat testing atau hot restart).
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Helper methods untuk operasi CRUD yang sering digunakan
  // ─────────────────────────────────────────────────────────────

  /// Insert satu baris ke tabel. Mengembalikan ID row yang di-insert.
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Query semua baris dari tabel dengan filter opsional.
  Future<List<Map<String, dynamic>>> queryAll(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Update baris yang cocok dengan kondisi [where].
  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  /// Hapus baris yang cocok dengan kondisi [where].
  Future<int> delete(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// Jalankan raw SQL query dan kembalikan hasilnya.
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// Eksekusi raw SQL tanpa hasil (untuk DDL atau INSERT/UPDATE kompleks).
  Future<void> rawExecute(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    await db.execute(sql, arguments);
  }

  /// Jalankan beberapa operasi dalam satu transaksi atomik.
  Future<T> runInTransaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }
}

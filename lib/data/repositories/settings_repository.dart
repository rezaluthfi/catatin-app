// Implementasi [ISettingsRepository] menggunakan kombinasi SQLite dan
// flutter_secure_storage (untuk PIN hash).
//
// Data sensitif (PIN hash, jawaban keamanan) disimpan di secure storage,
// sedangkan data non-sensitif (nama usaha) disimpan di SQLite biasa.
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/db_constants.dart';
import '../../core/database/database_helper.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/repositories/i_settings_repository.dart';
import '../models/settings_model.dart';

class SettingsRepository implements ISettingsRepository {
  SettingsRepository({
    DatabaseHelper? dbHelper,
    FlutterSecureStorage? secureStorage,
  })  : _db = dbHelper ?? DatabaseHelper.instance,
        _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final DatabaseHelper _db;
  final FlutterSecureStorage _secureStorage;

  @override
  Future<SettingsModel> getSettings() async {
    try {
      final rows = await _db.queryAll(DbConstants.tableSettings);
      final map = <String, String>{};
      for (final row in rows) {
        map[row[DbConstants.colSettingKey] as String] =
            row[DbConstants.colSettingValue] as String;
      }

      final pinHash = await _secureStorage.read(key: AppConstants.keyPinHash);
      final securityQuestion =
          await _secureStorage.read(key: AppConstants.keySecurityQuestion);
      final securityAnswerHash =
          await _secureStorage.read(key: AppConstants.keySecurityAnswerHash);

      if (pinHash != null) map[AppConstants.keyPinHash] = pinHash;
      if (securityQuestion != null) {
        map[AppConstants.keySecurityQuestion] = securityQuestion;
      }
      if (securityAnswerHash != null) {
        map[AppConstants.keySecurityAnswerHash] = securityAnswerHash;
      }

      return SettingsModel.fromMap(map);
    } catch (e) {
      throw DatabaseException('Gagal mengambil pengaturan', originalError: e);
    }
  }

  @override
  Future<void> saveBusinessName(String name) async {
    await _upsertSetting(AppConstants.keyBusinessName, name);
  }

  @override
  Future<void> saveOwnerName(String name) async {
    await _upsertSetting(AppConstants.keyOwnerName, name);
  }

  @override
  Future<void> saveDefaultMargin(int margin) async {
    await _upsertSetting(AppConstants.keyDefaultMargin, margin.toString());
  }

  @override
  Future<void> savePinHash(String pinHash) async {
    try {
      await _secureStorage.write(key: AppConstants.keyPinHash, value: pinHash);
    } catch (e) {
      throw DatabaseException('Gagal menyimpan PIN', originalError: e);
    }
  }

  @override
  Future<String?> getPinHash() async {
    try {
      return await _secureStorage.read(key: AppConstants.keyPinHash);
    } catch (e) {
      throw DatabaseException('Gagal membaca PIN', originalError: e);
    }
  }

  @override
  Future<void> saveSecurityInfo({
    required String question,
    required String answerHash,
  }) async {
    try {
      await _secureStorage.write(
        key: AppConstants.keySecurityQuestion,
        value: question,
      );
      await _secureStorage.write(
        key: AppConstants.keySecurityAnswerHash,
        value: answerHash,
      );
    } catch (e) {
      throw DatabaseException('Gagal menyimpan info keamanan', originalError: e);
    }
  }

  @override
  Future<bool> verifySecurityAnswer(String answerHash) async {
    try {
      final stored =
          await _secureStorage.read(key: AppConstants.keySecurityAnswerHash);
      return stored == answerHash;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String> exportToJson() async {
    try {
      final products = await _db.queryAll(DbConstants.tableProducts);
      final transactions = await _db.queryAll(DbConstants.tableTransactions);
      final transactionItems =
          await _db.queryAll(DbConstants.tableTransactionItems);
      final receivables = await _db.queryAll(DbConstants.tableReceivables);
      final operationalCosts =
          await _db.queryAll(DbConstants.tableOperationalCosts);
      final settings = await _db.queryAll(DbConstants.tableSettings);

      final backupData = {
        'version': AppConstants.appVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'data': {
          'products': products,
          'transactions': transactions,
          'transaction_items': transactionItems,
          'receivables': receivables,
          'operational_costs': operationalCosts,
          'settings': settings,
        },
      };

      return jsonEncode(backupData);
    } catch (e) {
      throw DatabaseException('Gagal mengekspor data', originalError: e);
    }
  }

  @override
  Future<void> importFromJson(String jsonString) async {
    try {
      final Map<String, dynamic> backup =
          jsonDecode(jsonString) as Map<String, dynamic>;
      final data = backup['data'] as Map<String, dynamic>;

      await _db.runInTransaction((txn) async {
        await txn.delete(DbConstants.tableTransactionItems);
        await txn.delete(DbConstants.tableReceivables);
        await txn.delete(DbConstants.tableOperationalCosts);
        await txn.delete(DbConstants.tableTransactions);
        await txn.delete(DbConstants.tableProducts);
        await txn.delete(DbConstants.tableSettings);

        for (final row in (data['products'] as List<dynamic>)) {
          await txn.insert(DbConstants.tableProducts,
              Map<String, dynamic>.from(row as Map));
        }
        for (final row in (data['transactions'] as List<dynamic>)) {
          await txn.insert(DbConstants.tableTransactions,
              Map<String, dynamic>.from(row as Map));
        }
        for (final row in (data['transaction_items'] as List<dynamic>)) {
          await txn.insert(DbConstants.tableTransactionItems,
              Map<String, dynamic>.from(row as Map));
        }
        for (final row in (data['receivables'] as List<dynamic>)) {
          await txn.insert(DbConstants.tableReceivables,
              Map<String, dynamic>.from(row as Map));
        }
        for (final row in (data['operational_costs'] as List<dynamic>)) {
          await txn.insert(DbConstants.tableOperationalCosts,
              Map<String, dynamic>.from(row as Map));
        }
        for (final row in (data['settings'] as List<dynamic>)) {
          await txn.insert(DbConstants.tableSettings,
              Map<String, dynamic>.from(row as Map));
        }
      });
    } catch (e) {
      throw DatabaseException('Gagal mengimpor data', originalError: e);
    }
  }

  Future<void> _upsertSetting(String key, String value) async {
    try {
      await _db.insert(DbConstants.tableSettings, {
        DbConstants.colSettingKey: key,
        DbConstants.colSettingValue: value,
      });
    } catch (e) {
      throw DatabaseException('Gagal menyimpan pengaturan', originalError: e);
    }
  }
}

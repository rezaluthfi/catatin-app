import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/dashboard/providers/dashboard_provider.dart';
import 'settings_state.dart';

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    return _loadSettings();
  }

  Future<SettingsState> _loadSettings() async {
    final repo = ref.read(settingsRepositoryProvider);
    final settings = await repo.getSettings();
    return SettingsState(
      businessName: settings.businessName,
      ownerName: settings.ownerName,
      defaultMargin: settings.defaultMargin,
    );
  }

  Future<void> updateBusinessName(String name) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.saveBusinessName(name);
    final current = state.valueOrNull ?? const SettingsState();
    state = AsyncData(current.copyWith(businessName: name));
    ref.invalidate(dashboardProvider);
  }

  Future<void> updateOwnerName(String name) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.saveOwnerName(name);
    final current = state.valueOrNull ?? const SettingsState();
    state = AsyncData(current.copyWith(ownerName: name));
  }

  Future<void> updateDefaultMargin(int margin) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.saveDefaultMargin(margin);
    final current = state.valueOrNull ?? const SettingsState();
    state = AsyncData(current.copyWith(defaultMargin: margin));
  }

  /// Export semua data ke file JSON dan tawarkan share sheet.
  /// Kembalikan path file jika berhasil, null jika gagal.
  Future<String?> exportData() async {
    final current = state.valueOrNull ?? const SettingsState();
    state = AsyncData(current.copyWith(isExporting: true, exportError: null));
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final jsonString = await repo.exportToJson();

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);
      final fileName =
          '${AppConstants.exportFileName}_$timestamp${AppConstants.exportFileExtension}';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonString);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Backup Data Catatin',
        text: 'Backup data Catatin - $timestamp',
      );

      state = AsyncData(current.copyWith(isExporting: false));
      return file.path;
    } catch (e) {
      state = AsyncData(current.copyWith(
        isExporting: false,
        exportError: e.toString(),
      ));
      return null;
    }
  }

  /// Import data dari JSON string (hasil baca file).
  Future<bool> importData(String jsonContent) async {
    final current = state.valueOrNull ?? const SettingsState();
    state = AsyncData(current.copyWith(isImporting: true, importError: null));
    try {
      // Validasi: pastikan ini file backup Catatin yang valid
      final decoded = jsonDecode(jsonContent) as Map<String, dynamic>;
      if (!decoded.containsKey('data') || !decoded.containsKey('version')) {
        throw Exception('File bukan backup Catatin yang valid');
      }

      final repo = ref.read(settingsRepositoryProvider);
      await repo.importFromJson(jsonContent);

      state = AsyncData(current.copyWith(isImporting: false));
      return true;
    } catch (e) {
      state = AsyncData(current.copyWith(
        isImporting: false,
        importError: e.toString(),
      ));
      return false;
    }
  }
}
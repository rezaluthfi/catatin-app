/// Entry point aplikasi CatatIn.
///
/// - Memastikan Flutter binding sudah diinisialisasi sebelum menjalankan app
/// - Membungkus seluruh app dengan [ProviderScope] (Riverpod)
/// - Inisialisasi intl locale untuk format Bahasa Indonesia
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app/app.dart';

Future<void> main() async {
  // Pastikan Flutter binding siap sebelum operasi async
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi FFI database jika berjalan di Windows atau Linux
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inisialisasi locale Bahasa Indonesia untuk format tanggal dan angka
  await initializeDateFormatting('id_ID');

  runApp(
    // ProviderScope adalah scope utama Riverpod — semua provider di-scope di sini
    const ProviderScope(child: CatatinApp()),
  );
}

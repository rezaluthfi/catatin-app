/// Root widget aplikasi Catatin.
///
/// Mengonfigurasi MaterialApp.router dengan go_router dan tema aplikasi.
/// ProviderScope (Riverpod) sudah di-wrap di main.dart.
import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class CatatinApp extends StatelessWidget {
  const CatatinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Catatin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}

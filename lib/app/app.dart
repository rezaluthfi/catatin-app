// Root widget aplikasi Catatin.
// Menggunakan ConsumerWidget agar bisa watch routerProvider dari Riverpod.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class CatatinApp extends ConsumerWidget {
  const CatatinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch routerProvider — GoRouter yang sudah terhubung ke RouterNotifier
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Catatin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

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
      title: 'CatatIn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        final textScaler = mediaQueryData.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.15,
        );
        return MediaQuery(
          data: mediaQueryData.copyWith(textScaler: textScaler),
          child: child!,
        );
      },
    );
  }
}

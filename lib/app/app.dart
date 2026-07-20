// Root widget aplikasi CatatIn.
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

        Widget appBody = child!;

        // Jika resolusi layar lebar (> 600px) seperti pada Windows desktop,
        // kita batasi lebar aplikasi agar tidak mulur dan tetap nyaman dibaca (centered mobile/tablet layout).
        if (mediaQueryData.size.width > 600) {
          appBody = Container(
            color: const Color(0xFFE2E8F0), // Background warna slate grey untuk area luar
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: MediaQuery(
                  data: mediaQueryData.copyWith(
                    size: Size(600, mediaQueryData.size.height),
                    textScaler: textScaler,
                  ),
                  child: child,
                ),
              ),
            ),
          );
        } else {
          appBody = MediaQuery(
            data: mediaQueryData.copyWith(textScaler: textScaler),
            child: child,
          );
        }

        return appBody;
      },
    );
  }
}

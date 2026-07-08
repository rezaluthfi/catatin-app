/// Screen setup PIN — ditampilkan saat pertama kali menggunakan aplikasi.
/// TODO (Sprint 2): Implementasi lengkap PIN setup flow.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';

class PinSetupScreen extends StatelessWidget {
  const PinSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat PIN')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64),
            const SizedBox(height: 16),
            const Text('Setup PIN — Coming Soon (Sprint 2)'),
            const SizedBox(height: 32),
            // Sementara langsung ke home untuk development
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Lewati (Dev Only)'),
            ),
          ],
        ),
      ),
    );
  }
}

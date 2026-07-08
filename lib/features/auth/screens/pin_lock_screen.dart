/// Screen PIN Lock — ditampilkan setiap kali aplikasi dibuka.
/// TODO (Sprint 2): Implementasi lengkap PIN lock + forgot PIN flow.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';

class PinLockScreen extends StatelessWidget {
  const PinLockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80),
            const SizedBox(height: 24),
            Text(
              'Catatin',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            const Text('Masukkan PIN Anda'),
            const SizedBox(height: 32),
            // Sementara langsung ke home untuk development
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Masuk (Dev Only)'),
            ),
          ],
        ),
      ),
    );
  }
}

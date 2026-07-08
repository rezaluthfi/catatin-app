/// Dashboard Screen — halaman utama aplikasi.
/// TODO (Sprint 6): Implementasi lengkap dashboard dengan summary cards.
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Center(
        child: Text('Dashboard — Coming Soon (Sprint 6)'),
      ),
    );
  }
}

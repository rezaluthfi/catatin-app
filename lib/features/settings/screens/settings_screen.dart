/// Settings Screen — pengaturan profil usaha dan PIN.
/// TODO (Sprint 8): Implementasi lengkap settings + export/import.
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil & Pengaturan')),
      body: const Center(
        child: Text('Pengaturan — Coming Soon (Sprint 8)'),
      ),
    );
  }
}

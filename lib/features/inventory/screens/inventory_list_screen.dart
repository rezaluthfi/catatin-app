/// Inventory List Screen — daftar semua produk/stok.
/// TODO (Sprint 3): Implementasi CRUD inventaris + price calculator.
import 'package:flutter/material.dart';

class InventoryListScreen extends StatelessWidget {
  const InventoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventarisasi')),
      body: const Center(
        child: Text('Inventarisasi — Coming Soon (Sprint 3)'),
      ),
    );
  }
}

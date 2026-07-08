/// POS Screen — halaman pencatatan transaksi.
/// TODO (Sprint 4): Implementasi cart + checkout + kasbon flow.
import 'package:flutter/material.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catat Transaksi')),
      body: const Center(
        child: Text('POS — Coming Soon (Sprint 4)'),
      ),
    );
  }
}

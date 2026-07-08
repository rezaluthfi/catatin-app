/// Recap Screen — rekapitulasi harian, mingguan, dan bulanan.
/// TODO (Sprint 7): Implementasi tab harian/mingguan/bulanan + chart.
import 'package:flutter/material.dart';

class RecapScreen extends StatelessWidget {
  const RecapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rekapitulasi')),
      body: const Center(
        child: Text('Rekapitulasi — Coming Soon (Sprint 7)'),
      ),
    );
  }
}

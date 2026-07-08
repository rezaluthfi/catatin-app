/// Product Form Screen — form tambah/edit produk.
/// Dapat digunakan untuk add (productId = null) maupun edit (productId terisi).
/// TODO (Sprint 3): Implementasi lengkap termasuk bantuan harga jual.
import 'package:flutter/material.dart';

class ProductFormScreen extends StatelessWidget {
  const ProductFormScreen({super.key, this.productId});

  /// Jika null, berarti mode tambah produk baru.
  /// Jika terisi, berarti mode edit produk yang sudah ada.
  final String? productId;

  bool get isEditing => productId != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Produk' : 'Tambah Produk'),
      ),
      body: Center(
        child: Text(
          isEditing
              ? 'Edit Produk ($productId) — Coming Soon (Sprint 3)'
              : 'Tambah Produk — Coming Soon (Sprint 3)',
        ),
      ),
    );
  }
}

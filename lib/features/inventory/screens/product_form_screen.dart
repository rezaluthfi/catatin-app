import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/extensions/currency_extension.dart';
import '../../../data/models/product_model.dart';
import '../providers/inventory_provider.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  final String? productId;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _stockController = TextEditingController();

  bool _isLoading = false;
  ProductModel? _existingProduct;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _loadProductData();
    }
  }

  void _loadProductData() {
    final state = ref.read(inventoryProvider).valueOrNull;
    if (state != null) {
      final match = state.products.where((p) => p.id == widget.productId);
      if (match.isNotEmpty) {
        _existingProduct = match.first;
        _nameController.text = _existingProduct!.name;
        _purchasePriceController.text = _existingProduct!.purchasePrice.toString();
        _sellingPriceController.text = _existingProduct!.sellingPrice.toString();
        _stockController.text = _existingProduct!.stock.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final purchasePrice = int.parse(_purchasePriceController.text.trim());
      final sellingPrice = int.parse(_sellingPriceController.text.trim());
      final stock = int.parse(_stockController.text.trim());
      final now = DateTime.now();
      if (_existingProduct != null) {
        // Edit
        final updatedProduct = _existingProduct!.copyWith(
          name: name,
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          stock: stock,
          updatedAt: now,
        );
        await ref.read(inventoryProvider.notifier).updateProduct(updatedProduct);
      } else {
        // Add
        final newProduct = ProductModel(
          id: const Uuid().v4(), // Placeholder, di-replace di repo
          name: name,
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          stock: stock,
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(inventoryProvider.notifier).addProduct(newProduct);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_existingProduct != null
                ? 'Produk berhasil diperbarui!'
                : 'Produk berhasil ditambahkan!'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop(); // Kembali ke list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan produk: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _existingProduct != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Ubah Produk' : 'Tambah Produk',
          style: AppTextStyles.headlineMedium,
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Nama Produk', style: AppTextStyles.labelMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Mis: Kopi Susu Aren',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Nama produk wajib diisi';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Harga Modal', style: AppTextStyles.labelMedium),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _purchasePriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '0',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 12, right: 8, top: 14, bottom: 14),
                              child: Text(
                                'Rp',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Wajib diisi';
                            if (int.tryParse(val) == null) return 'Harus angka';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Harga Jual', style: AppTextStyles.labelMedium),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _sellingPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '0',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 12, right: 8, top: 14, bottom: 14),
                              child: Text(
                                'Rp',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Wajib diisi';
                            if (int.tryParse(val) == null) return 'Harus angka';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _purchasePriceController,
                builder: (context, value, child) {
                  final purchasePrice = int.tryParse(value.text);
                  if (purchasePrice == null || purchasePrice <= 0) {
                    return const SizedBox(height: 20);
                  }
                  final margin = purchasePrice * 0.3;
                  final recommended = ((purchasePrice + margin) / 100).ceil() * 100;

                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    child: InkWell(
                      onTap: () {
                        _sellingPriceController.text = recommended.toString();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Rekomendasi Harga Jual: ${recommended.toRupiah()} (Margin 30%)',
                                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              Text('Stok Awal', style: AppTextStyles.labelMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Jumlah stok (mis: 10)',
                  prefixIcon: Icon(Icons.numbers_rounded),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Stok wajib diisi';
                  if (int.tryParse(val) == null) return 'Harus berupa angka';
                  return null;
                },
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(isEdit ? 'Simpan Perubahan' : 'Simpan Produk'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: const Text('Apakah Anda yakin ingin menghapus produk ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteProduct();
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct() async {
    if (_existingProduct == null) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(inventoryProvider.notifier).deleteProduct(_existingProduct!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil dihapus!'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop(); // Kembali ke list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus produk: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

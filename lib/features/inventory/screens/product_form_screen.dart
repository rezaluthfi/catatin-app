import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' show join;
import 'package:image_cropper/image_cropper.dart';

import '../../../core/services/app_directory_service.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/extensions/currency_extension.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/product_stock_history_model.dart';
import '../providers/inventory_provider.dart';
import '../../settings/providers/settings_provider.dart';

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
  final _dateController = TextEditingController();

  bool _isLoading = false;
  bool _isStockAdd = true;
  ProductModel? _existingProduct;
  ProductModel? _selectedEtalaseProduct;

  String? _selectedImagePath;
  DateTime _selectedDate = DateTime.now();
  int _historyCurrentPage = 1;
  static const int _historyPageSize = 10;

  @override
  void initState() {
    super.initState();
    _dateController.text = _formatDate(_selectedDate);
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
        _purchasePriceController.text = _existingProduct!.purchasePrice
            .toRupiahNoSymbol();
        _sellingPriceController.text = _existingProduct!.sellingPrice
            .toRupiahNoSymbol();
        _selectedDate = _existingProduct!.updatedAt;
        _dateController.text = _formatDate(_selectedDate);
        _selectedImagePath = _existingProduct!.imagePath;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final initial = _selectedDate.isAfter(now) ? now : _selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        if (Platform.isWindows || Platform.isLinux) {
          setState(() {
            _selectedImagePath = pickedFile.path;
          });
        } else {
          await _cropImage(pickedFile.path);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  Future<void> _cropImage(String filePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: filePath,
        aspectRatio: const CropAspectRatio(
          ratioX: 1,
          ratioY: 1,
        ), // Square aspect ratio
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Potong Foto Produk',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Potong Foto Produk',
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      if (croppedFile != null) {
        setState(() {
          _selectedImagePath = croppedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memotong gambar: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isDesktop)
                      ListTile(
                        leading: const Icon(
                          Icons.camera_alt_outlined,
                          color: AppColors.primary,
                        ),
                        title: const Text('Ambil dari Kamera'),
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ListTile(
                      leading: const Icon(
                        Icons.photo_library_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        isDesktop ? 'Pilih dari Berkas Komputer' : 'Pilih dari Galeri',
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    if (_selectedImagePath != null ||
                        _existingProduct?.imagePath != null)
                      ListTile(
                        leading: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.expense,
                        ),
                        title: const Text(
                          'Hapus Foto',
                          style: TextStyle(color: AppColors.expense),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _selectedImagePath = ''; // Menandai dihapus
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageWidget() {
    if (_selectedImagePath == '') {
      return _buildImagePlaceholder();
    }

    final path = _selectedImagePath ?? _existingProduct?.imagePath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(file, fit: BoxFit.cover),
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        );
      }
    }
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_a_photo_rounded,
          color: AppColors.textSecondary,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          'Tambah Foto',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final purchasePrice = int.parse(
        _purchasePriceController.text.replaceAll('.', '').trim(),
      );
      final sellingPrice = int.parse(
        _sellingPriceController.text.replaceAll('.', '').trim(),
      );
      final inputQty = int.tryParse(_stockController.text.trim()) ?? 0;

      String? finalImagePath;
      if (_selectedImagePath == '') {
        finalImagePath = null; // Dihapus oleh user
      } else if (_selectedImagePath != null &&
          _selectedImagePath != _existingProduct?.imagePath) {
        // Salin file ke folder produk aplikasi agar aman
        final imgDir = await AppDirectoryService.getProductImagesDirectory();
        final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedFile = await File(
          _selectedImagePath!,
        ).copy(join(imgDir.path, fileName));
        finalImagePath = savedFile.path;
      } else {
        finalImagePath = _existingProduct?.imagePath;
      }

      if (_existingProduct != null) {
        // Edit produk
        final delta = _isStockAdd ? inputQty : -inputQty;
        final newStock = _existingProduct!.stock + delta;

        final updatedProduct = _existingProduct!.copyWith(
          name: name,
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          stock: newStock,
          imagePath: () => finalImagePath,
          updatedAt: _selectedDate,
        );
        await ref
            .read(inventoryProvider.notifier)
            .updateProduct(updatedProduct);
      } else {
        // Add produk
        if (_selectedEtalaseProduct != null) {
          final delta = _isStockAdd ? inputQty : -inputQty;
          final updatedProduct = _selectedEtalaseProduct!.copyWith(
            purchasePrice: purchasePrice,
            sellingPrice: sellingPrice,
            stock: _selectedEtalaseProduct!.stock + delta,
            imagePath: () =>
                finalImagePath ?? _selectedEtalaseProduct!.imagePath,
            updatedAt: _selectedDate,
          );
          await ref
              .read(inventoryProvider.notifier)
              .updateProduct(updatedProduct);
        } else {
          // Produk baru
          final newProduct = ProductModel(
            id: const Uuid().v4(),
            name: name,
            purchasePrice: purchasePrice,
            sellingPrice: sellingPrice,
            stock: inputQty,
            imagePath: finalImagePath,
            createdAt: _selectedDate,
            updatedAt: _selectedDate,
          );
          await ref.read(inventoryProvider.notifier).addProduct(newProduct);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _existingProduct != null
                  ? 'Produk berhasil diperbarui!'
                  : (_selectedEtalaseProduct != null
                        ? 'Stok produk etalase berhasil diperbarui!'
                        : 'Produk baru berhasil ditambahkan!'),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.pop(); // Kembali ke list
          }
        });
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
    final settings = ref.watch(settingsProvider).valueOrNull;
    final defaultMargin = settings?.defaultMargin ?? 30;

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
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.expense,
              ),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
              // -- INPUT FOTO PRODUK --
              Center(
                child: GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: _buildImageWidget(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text('Nama Produk', style: AppTextStyles.labelMedium),
              const SizedBox(height: 8),
              if (isEdit)
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Mis: Kopi Susu Aren',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama produk wajib diisi';
                    }
                    return null;
                  },
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final allProducts =
                        ref.watch(inventoryProvider).valueOrNull?.products ??
                        [];
                    return RawAutocomplete<ProductModel>(
                      focusNode: FocusNode(),
                      textEditingController: _nameController,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.trim().isEmpty) {
                          return const Iterable<ProductModel>.empty();
                        }
                        final query = textEditingValue.text.toLowerCase();
                        return allProducts.where(
                          (p) => p.name.toLowerCase().contains(query),
                        );
                      },
                      displayStringForOption: (ProductModel option) =>
                          option.name,
                      onSelected: (ProductModel selection) {
                        setState(() {
                          _nameController.text = selection.name;
                          _purchasePriceController.text = selection
                              .purchasePrice
                              .toRupiahNoSymbol();
                          _sellingPriceController.text = selection.sellingPrice
                              .toRupiahNoSymbol();
                          _selectedEtalaseProduct = selection;
                        });
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                hintText: 'Cari atau ketik nama produk...',
                                prefixIcon: Icon(Icons.inventory_2_outlined),
                              ),
                              onChanged: (val) {
                                final match = allProducts.where(
                                  (p) =>
                                      p.name.trim().toLowerCase() ==
                                      val.trim().toLowerCase(),
                                );
                                setState(() {
                                  _selectedEtalaseProduct = match.isNotEmpty
                                      ? match.first
                                      : null;
                                });
                              },
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Nama produk wajib diisi';
                                }
                                return null;
                              },
                            );
                          },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.surface,
                            child: SizedBox(
                              width: constraints.maxWidth,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final ProductModel option = options.elementAt(
                                    index,
                                  );
                                  return ListTile(
                                    title: Text(
                                      option.name,
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                    subtitle: Text(
                                      'Stok saat ini: ${option.stock} | Modal: ${option.purchasePrice.toRupiah()} | Jual: ${option.sellingPrice.toRupiah()}',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    onTap: () {
                                      onSelected(option);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
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
                          inputFormatters: [CurrencyInputFormatter()],
                          decoration: const InputDecoration(
                            hintText: '0',
                            prefixText: 'Rp',
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Wajib diisi';
                            }
                            if (int.tryParse(val.replaceAll('.', '')) == null) {
                              return 'Harus angka';
                            }
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
                          inputFormatters: [CurrencyInputFormatter()],
                          decoration: const InputDecoration(
                            hintText: '0',
                            prefixText: 'Rp',
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Wajib diisi';
                            }
                            if (int.tryParse(val.replaceAll('.', '')) == null) {
                              return 'Harus angka';
                            }
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
                  final purchasePrice = int.tryParse(
                    value.text.replaceAll('.', ''),
                  );
                  if (purchasePrice == null || purchasePrice <= 0) {
                    return const SizedBox(height: 20);
                  }
                  final margin = purchasePrice * (defaultMargin / 100);
                  final recommended =
                      ((purchasePrice + margin) / 100).ceil() * 100;

                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    child: InkWell(
                      onTap: () {
                        _sellingPriceController.text = recommended
                            .toRupiahNoSymbol();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 4.0,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Rekomendasi Harga Jual: ${recommended.toRupiah()} (Margin $defaultMargin%)',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Mode Penyesuaian Stok: Jika edit ATAU pilih produk etalase
              if (isEdit || _selectedEtalaseProduct != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Jenis Penyesuaian', style: AppTextStyles.labelMedium),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Stok saat ini: ${isEdit ? _existingProduct!.stock : _selectedEtalaseProduct!.stock}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    showSelectedIcon: true,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.primary;
                        }
                        return AppColors.surface;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith<Color?>((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return AppColors.textPrimary;
                      }),
                      iconColor: WidgetStateProperty.resolveWith<Color?>((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return AppColors.textPrimary;
                      }),
                    ),
                    segments: [
                      ButtonSegment<bool>(
                        value: true,
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Tambah Stok (+)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 16),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Kurang Stok (-)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.remove_rounded, size: 16),
                      ),
                    ],
                    selected: {_isStockAdd},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _isStockAdd = newSelection.first;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isStockAdd
                      ? 'Jumlah Stok Tambahan'
                      : 'Jumlah Stok yang Dikurangi',
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: _isStockAdd
                        ? 'Jumlah barang tambahan (opsional)'
                        : 'Jumlah barang yang dikurangi (opsional)',
                    prefixIcon: Icon(
                      _isStockAdd
                          ? Icons.add_circle_outline_rounded
                          : Icons.remove_circle_outline_rounded,
                      color: _isStockAdd
                          ? AppColors.primary
                          : AppColors.expense,
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return null;
                    }
                    final numVal = int.tryParse(val);
                    if (numVal == null || numVal <= 0) {
                      return 'Masukkan angka lebih dari 0';
                    }
                    final currentStock = isEdit
                        ? _existingProduct!.stock
                        : _selectedEtalaseProduct!.stock;
                    if (!_isStockAdd && numVal > currentStock) {
                      return 'Pengurangan melebihi stok yang ada ($currentStock unit)';
                    }
                    return null;
                  },
                ),
              ] else ...[
                Text('Stok Awal', style: AppTextStyles.labelMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Jumlah stok awal (mis: 10)',
                    prefixIcon: Icon(Icons.numbers_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Stok wajib diisi';
                    }
                    final numVal = int.tryParse(val);
                    if (numVal == null || numVal < 0) {
                      return 'Masukkan angka valid';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 20),

              Text(
                isEdit ? 'Tanggal Perubahan Stok' : 'Tanggal Masuk Stok',
                style: AppTextStyles.labelMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _selectDate,
                decoration: const InputDecoration(
                  hintText: 'Pilih Tanggal',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                  suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                ),
              ),
              const SizedBox(height: 32),

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

              // -- DETAIL RIWAYAT STOK (EDIT MODE) --
              if (isEdit) _buildHistorySection(),
            ],
          ),
        ),
      ),
    ),
  ),
);
}

  Widget _buildHistorySection() {
    if (_existingProduct == null) return const SizedBox.shrink();

    final historyAsync = ref.watch(
      productStockHistoryProvider(_existingProduct!.id),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 24),
        Text(
          'Riwayat Harga & Stok',
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Catatan perubahan stok dan harga beli produk',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        historyAsync.when(
          data: (List<ProductStockHistoryModel> historyList) {
            if (historyList.isEmpty) {
              return Card(
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Belum ada riwayat stok tercatat',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }

            final hasPriceDiff =
                historyList.map((h) => h.purchasePrice).toSet().length > 1;

            final totalPages = (historyList.length / _historyPageSize).ceil();
            final safePage = _historyCurrentPage > totalPages
                ? totalPages
                : (_historyCurrentPage < 1 ? 1 : _historyCurrentPage);
            final startIndex = (safePage - 1) * _historyPageSize;
            final endIndex =
                (startIndex + _historyPageSize < historyList.length)
                ? startIndex + _historyPageSize
                : historyList.length;
            final pageList = historyList.sublist(startIndex, endIndex);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pageList.length,
                  itemBuilder: (context, index) {
                    final item = pageList[index];
                    final isPositive = item.stockAdded >= 0;
                    final priceColor = hasPriceDiff
                        ? AppColors.warning
                        : AppColors.textPrimary;

                    final isPosTx = item.id.startsWith('pos_');
                    final IconData iconData;
                    final Color iconColor;
                    final String labelText;

                    if (isPositive) {
                      iconData = Icons.add_rounded;
                      iconColor = AppColors.income;
                      labelText = 'Tambah Stok: +${item.stockAdded} pcs';
                    } else if (isPosTx) {
                      iconData = Icons.shopping_bag_rounded;
                      iconColor = AppColors.primary;
                      labelText = 'Penjualan: ${item.stockAdded} pcs';
                    } else {
                      iconData = Icons.remove_rounded;
                      iconColor = AppColors.expense;
                      labelText = 'Kurang Stok: ${item.stockAdded} pcs';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(iconData, color: iconColor, size: 20),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: FittedBox(
                                alignment: Alignment.centerLeft,
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  labelText,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            if (hasPriceDiff)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Beda Harga',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tanggal Stok: ${_formatDate(item.date)}',
                                style: AppTextStyles.bodySmall,
                              ),
                              const SizedBox(height: 2),
                              RichText(
                                text: TextSpan(
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Harga Beli: '),
                                    TextSpan(
                                      text: item.purchasePrice.toRupiah(),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: priceColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (totalPages > 1) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: safePage > 1
                            ? () {
                                setState(() {
                                  _historyCurrentPage = safePage - 1;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: safePage > 1
                              ? AppColors.primaryContainer
                              : AppColors.surfaceVariant,
                          foregroundColor: safePage > 1
                              ? AppColors.primary
                              : AppColors.textDisabled,
                        ),
                        tooltip: 'Halaman Sebelumnya',
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Halaman $safePage dari $totalPages',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: safePage < totalPages
                            ? () {
                                setState(() {
                                  _historyCurrentPage = safePage + 1;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: safePage < totalPages
                              ? AppColors.primaryContainer
                              : AppColors.surfaceVariant,
                          foregroundColor: safePage < totalPages
                              ? AppColors.primary
                              : AppColors.textDisabled,
                        ),
                        tooltip: 'Halaman Selanjutnya',
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Gagal memuat riwayat: $err',
                style: const TextStyle(color: AppColors.expense),
              ),
            ),
          ),
        ),
      ],
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
            child: Text(
              'Hapus',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.expense,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct() async {
    if (_existingProduct == null) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(inventoryProvider.notifier)
          .deleteProduct(_existingProduct!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil dihapus!'),
            backgroundColor: AppColors.primary,
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.pop(); // Kembali ke list
          }
        });
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

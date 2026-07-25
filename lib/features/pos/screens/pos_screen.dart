// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/extensions/currency_extension.dart';
import '../models/cart_item_model.dart';
import '../../../data/models/transaction_enums.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../../inventory/widgets/empty_inventory_widget.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/pos_provider.dart';
import '../providers/pos_state.dart';
import '../widgets/cart_bottom_sheet.dart';
import '../widgets/checkout_bottom_sheet.dart';
import '../../inventory/providers/inventory_state.dart';
import '../widgets/pos_product_card.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();

  // Desktop Inline Checkout State
  bool _isCheckoutMode = false;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String _nonCashType = 'qris';
  String? _selectedBankAccount;
  int _cashReceived = 0;
  bool _submitted = false;

  final _notesController = TextEditingController();
  final _cashController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _dueDateController = TextEditingController();
  DateTime? _dueDate;

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    _cashController.dispose();
    _customerNameController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  void _onCashChanged(String value) {
    final numericString = value.replaceAll(RegExp(r'[^0-9]'), '');
    final intValue = int.tryParse(numericString) ?? 0;

    if (numericString.isNotEmpty) {
      final formatted = intValue.toRupiahNoSymbol();
      _cashController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else {
      _cashController.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    setState(() {
      _cashReceived = intValue;
    });
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
        _dueDateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _submitDesktopTransaction() async {
    final posState = ref.read(posProvider);
    final total = posState.totalAmount;

    setState(() {
      _submitted = true;
    });

    if (_paymentMethod == PaymentMethod.cash) {
      if (_cashController.text.trim().isEmpty || _cashReceived < total) {
        return;
      }
    }

    if (_paymentMethod == PaymentMethod.credit &&
        _customerNameController.text.trim().isEmpty) {
      return;
    }

    final success = await ref
        .read(posProvider.notifier)
        .checkout(
          paymentMethod: _paymentMethod,
          customerName: _paymentMethod == PaymentMethod.credit
              ? _customerNameController.text.trim()
              : null,
          dueDate: _paymentMethod == PaymentMethod.credit ? _dueDate : null,
          nonCashType: _paymentMethod == PaymentMethod.nonCash
              ? _nonCashType
              : null,
          bankAccount: _paymentMethod == PaymentMethod.nonCash
              ? _selectedBankAccount
              : null,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      setState(() {
        _isCheckoutMode = false;
        _submitted = false;
        _cashReceived = 0;
        _cashController.clear();
        _customerNameController.clear();
        _dueDateController.clear();
        _notesController.clear();
        _dueDate = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil disimpan!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      final errorMsg = ref.read(posProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg ?? 'Gagal menyimpan transaksi'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CartBottomSheet(
        onCheckout: _showCheckoutSheet,
      ),
    );
  }

  void _showCheckoutSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CheckoutBottomSheet(
        onBackToCart: () {
          Navigator.pop(context);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (MediaQuery.of(context).size.width < 768) {
              _showCartSheet();
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    final posState = ref.watch(posProvider);
    final cartItems = posState.cartItems;
    final totalItems = posState.totalItems;
    final totalAmount = posState.totalAmount;

    final inventoryState = ref.watch(inventoryProvider).valueOrNull;
    final allProducts = inventoryState?.products ?? [];

    final searchQuery = posState.searchQuery.toLowerCase();
    final displayedProducts = allProducts.where((p) {
      if (searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Catat Transaksi', style: AppTextStyles.headlineMedium),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded, color: AppColors.textPrimary),
            onPressed: () => _showSortModal(context, ref),
          ),
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                // --- DESKTOP LEFT: PRODUCT LIST & SEARCH ---
                Expanded(
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        color: AppColors.surface,
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            ref.read(posProvider.notifier).setSearchQuery(val);
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari produk...',
                            hintStyle: AppTextStyles.bodyMediumSecondary,
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.textSecondary,
                            ),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref
                                          .read(posProvider.notifier)
                                          .setSearchQuery('');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),

                      // Daftar Produk Grid
                      Expanded(
                        child: displayedProducts.isEmpty
                            ? EmptyInventoryWidget(
                                isSearch: searchQuery.isNotEmpty,
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.all(24),
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 220,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.65,
                                ),
                                itemCount: displayedProducts.length,
                                itemBuilder: (context, index) {
                                  return PosProductCard(
                                    product: displayedProducts[index],
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),

                // --- DESKTOP RIGHT: PERSISTENT INLINE POS PANEL ---
                _buildDesktopRightPanel(
                  context,
                  posState,
                  cartItems,
                  totalAmount,
                ),
              ],
            )
          // --- MOBILE LAYOUT ---
          : Column(
              children: [
                // Search Bar
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(posProvider.notifier).setSearchQuery(val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari produk...',
                      hintStyle: AppTextStyles.bodyMediumSecondary,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(posProvider.notifier)
                                    .setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // Daftar Produk (Grid)
                Expanded(
                  child: displayedProducts.isEmpty
                      ? EmptyInventoryWidget(isSearch: searchQuery.isNotEmpty)
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.65,
                          ),
                          itemCount: displayedProducts.length,
                          itemBuilder: (context, index) {
                            return PosProductCard(
                              product: displayedProducts[index],
                            );
                          },
                        ),
                ),
              ],
            ),

      // Floating Bottom Bar untuk Keranjang (Mobile only)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: isDesktop || cartItems.isEmpty
          ? null
          : Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showCartSheet,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$totalItems',
                                  style: AppTextStyles.headingSmall.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Belanja',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.8),
                                      ),
                                    ),
                                    Text(
                                      totalAmount.toRupiah(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.headingSmall
                                          .copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            Text(
                              'Lihat',
                              style: AppTextStyles.headingSmall.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDesktopRightPanel(
    BuildContext context,
    PosState posState,
    List<CartItemModel> cartItems,
    int totalAmount,
  ) {
    if (cartItems.isEmpty && _isCheckoutMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isCheckoutMode = false);
      });
    }

    return Container(
      width: 400,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: _isCheckoutMode
          ? _buildDesktopCheckoutStep(context, posState, totalAmount)
          : _buildDesktopCartStep(context, posState, cartItems, totalAmount),
    );
  }

  Widget _buildDesktopCartStep(
    BuildContext context,
    PosState posState,
    List<CartItemModel> cartItems,
    int totalAmount,
  ) {
    return Column(
      children: [
        // Cart Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Keranjang Belanja',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (cartItems.isNotEmpty)
                TextButton(
                  onPressed: () {
                    ref.read(posProvider.notifier).clearCart();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Kosongkan',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.expense,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        // Cart Items / Empty State
        Expanded(
          child: cartItems.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Keranjang masih kosong',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Klik produk di sebelah kiri untuk menambahkan ke kasir.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: cartItems.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    color: AppColors.border,
                  ),
                  itemBuilder: (context, index) {
                    return CartItemRow(item: cartItems[index]);
                  },
                ),
        ),

        const Divider(height: 1, color: AppColors.border),

        // Cart Footer & Checkout Button
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Tagihan', style: AppTextStyles.labelLarge),
                  Text(
                    totalAmount.toRupiah(),
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: cartItems.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _isCheckoutMode = true;
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Lanjut Pembayaran',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopCheckoutStep(
    BuildContext context,
    PosState posState,
    int totalAmount,
  ) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final bankAccounts = settings?.bankAccounts ?? [];
    final change = _cashReceived - totalAmount;
    final hasEnteredCash = _cashController.text.isNotEmpty;
    final isCashError = hasEnteredCash && change < 0;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _isCheckoutMode = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Text(
                'Pembayaran',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Total Tagihan Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Tagihan',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        totalAmount.toRupiah(),
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Metode Pembayaran Chips
                Text('Metode Pembayaran', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentMethodChoice(
                        PaymentMethod.cash,
                        'Tunai',
                        Icons.payments_outlined,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildPaymentMethodChoice(
                        PaymentMethod.nonCash,
                        'Non-Tunai',
                        Icons.qr_code_scanner_rounded,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildPaymentMethodChoice(
                        PaymentMethod.credit,
                        'Piutang',
                        Icons.assignment_ind_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // TUNAI MODE INPUTS
                if (_paymentMethod == PaymentMethod.cash) ...[
                  // Quick Uang Pas Button
                  OutlinedButton.icon(
                    onPressed: () {
                      final formatted = totalAmount.toRupiahNoSymbol();
                      _cashController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                      setState(() => _cashReceived = totalAmount);
                    },
                    icon: const Icon(Icons.touch_app_outlined, size: 18),
                    label: Text('Uang Pas: ${totalAmount.toRupiah()}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _cashController,
                    keyboardType: TextInputType.number,
                    onChanged: _onCashChanged,
                    decoration: InputDecoration(
                      labelText: 'Uang Diterima',
                      prefixText: 'Rp ',
                      errorText: _submitted && _cashController.text.isEmpty
                          ? 'Nominal wajib diisi'
                          : isCashError
                              ? 'Nominal uang kurang'
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Kembalian Card
                  if (hasEnteredCash)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: change >= 0
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.expense.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            change >= 0 ? 'Kembalian' : 'Kekurangan',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: change >= 0
                                  ? AppColors.primary
                                  : AppColors.expense,
                            ),
                          ),
                          Text(
                            (change >= 0 ? change : -change).toRupiah(),
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: change >= 0
                                  ? AppColors.primary
                                  : AppColors.expense,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                // NON-TUNAI MODE INPUTS
                if (_paymentMethod == PaymentMethod.nonCash) ...[
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('QRIS'),
                        selected: _nonCashType == 'qris',
                        onSelected: (_) =>
                            setState(() => _nonCashType = 'qris'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Transfer Bank'),
                        selected: _nonCashType == 'bank',
                        onSelected: (_) =>
                            setState(() => _nonCashType = 'bank'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (bankAccounts.isEmpty)
                    InkWell(
                      onTap: () {
                        context.go(AppRoutes.settings);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.expense.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.expense,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Belum ada rekening/e-wallet terdaftar.',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.expense,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ketuk di sini untuk mendaftarkan di profil/pengaturan.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.expense.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    (() {
                      if (_selectedBankAccount != null &&
                          !bankAccounts.contains(_selectedBankAccount)) {
                        _selectedBankAccount = null;
                      }
                      _selectedBankAccount ??= bankAccounts.first;

                      return DropdownButtonFormField<String>(
                        value: _selectedBankAccount,
                        decoration: InputDecoration(
                          labelText: 'Pilih Rekening / E-Wallet Tujuan',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: bankAccounts.map((acc) {
                          return DropdownMenuItem(value: acc, child: Text(acc));
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedBankAccount = val),
                      );
                    })(),
                  ],
                ],

                // PIUTANG MODE INPUTS
                if (_paymentMethod == PaymentMethod.credit) ...[
                  TextField(
                    controller: _customerNameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Pelanggan / Pembeli *',
                      errorText:
                          _submitted && _customerNameController.text.isEmpty
                              ? 'Nama pelanggan wajib diisi'
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dueDateController,
                    readOnly: true,
                    onTap: _selectDueDate,
                    decoration: InputDecoration(
                      labelText: 'Tanggal Jatuh Tempo',
                      suffixIcon: const Icon(Icons.calendar_today_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Catatan (Opsional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed:
                        posState.isLoading ? null : _submitDesktopTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: posState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Selesaikan Transaksi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => setState(() => _isCheckoutMode = false),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Kembali ke Keranjang'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodChoice(
    PaymentMethod method,
    String label,
    IconData icon,
  ) {
    final isSelected = _paymentMethod == method;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _paymentMethod = method),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentState = ref.watch(inventoryProvider).valueOrNull;
            if (currentState == null) return const SizedBox();

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Filter', style: AppTextStyles.headlineSmall),
                          (() {
                            final hasFilters = currentState.showLowStockOnly ||
                                currentState.showOutOfStockOnly;
                            final hasDefaultSort =
                                currentState.sortTypes.length == 1 &&
                                    currentState.sortTypes.first ==
                                        ProductSortType.nameAsc;
                            final isDirty = hasFilters || !hasDefaultSort;
                            if (isDirty) {
                              return TextButton(
                                onPressed: () {
                                  ref
                                      .read(inventoryProvider.notifier)
                                      .clearFilters();
                                  Navigator.pop(context);
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Reset'),
                              );
                            }
                            return const SizedBox();
                          })(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFilterOption(
                      context,
                      ref,
                      title: 'Tampilkan Stok Menipis Saja',
                      value: currentState.showLowStockOnly,
                      onChanged: (_) {
                        ref
                            .read(inventoryProvider.notifier)
                            .toggleLowStockFilter();
                        Navigator.pop(context);
                      },
                    ),
                    _buildFilterOption(
                      context,
                      ref,
                      title: 'Tampilkan Stok Habis Saja',
                      value: currentState.showOutOfStockOnly,
                      onChanged: (_) {
                        ref
                            .read(inventoryProvider.notifier)
                            .toggleOutOfStockFilter();
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Urutkan Berdasarkan',
                        style: AppTextStyles.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSortOption(
                      context,
                      ref,
                      title: 'Nama (A-Z)',
                      value: ProductSortType.nameAsc,
                      sortTypes: currentState.sortTypes,
                    ),
                    _buildSortOption(
                      context,
                      ref,
                      title: 'Nama (Z-A)',
                      value: ProductSortType.nameDesc,
                      sortTypes: currentState.sortTypes,
                    ),
                    _buildSortOption(
                      context,
                      ref,
                      title: 'Stok Terbanyak',
                      value: ProductSortType.stockDesc,
                      sortTypes: currentState.sortTypes,
                    ),
                    _buildSortOption(
                      context,
                      ref,
                      title: 'Stok Sedikit',
                      value: ProductSortType.stockAsc,
                      sortTypes: currentState.sortTypes,
                    ),
                    _buildSortOption(
                      context,
                      ref,
                      title: 'Harga Tertinggi',
                      value: ProductSortType.priceDesc,
                      sortTypes: currentState.sortTypes,
                    ),
                    _buildSortOption(
                      context,
                      ref,
                      title: 'Harga Terendah',
                      value: ProductSortType.priceAsc,
                      sortTypes: currentState.sortTypes,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Terapkan'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: value ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      activeColor: AppColors.primary,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required ProductSortType value,
    required List<ProductSortType> sortTypes,
  }) {
    final index = sortTypes.indexOf(value);
    final isSelected = index >= 0;

    return CheckboxListTile(
      value: isSelected,
      onChanged: (_) {
        ref.read(inventoryProvider.notifier).toggleSortType(value);
      },
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      activeColor: AppColors.primary,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}

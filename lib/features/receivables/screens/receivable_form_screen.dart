import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/extensions/currency_extension.dart';
import '../providers/receivable_provider.dart';

class ReceivableFormScreen extends ConsumerStatefulWidget {
  const ReceivableFormScreen({super.key});

  @override
  ConsumerState<ReceivableFormScreen> createState() => _ReceivableFormScreenState();
}

class _ReceivableFormScreenState extends ConsumerState<ReceivableFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _dueDate;
  int _amount = 0;

  @override
  void dispose() {
    _customerNameController.dispose();
    _amountController.dispose();
    _dueDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String value) {
    final numericString = value.replaceAll(RegExp(r'[^0-9]'), '');
    final intValue = int.tryParse(numericString) ?? 0;

    if (numericString.isNotEmpty) {
      final formatted = intValue.toRupiahNoSymbol();
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else {
      _amountController.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    setState(() {
      _amount = intValue;
    });
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Future<void> _saveReceivable() async {
    if (!_formKey.currentState!.validate() || _amount <= 0) {
      return;
    }

    final customerName = _customerNameController.text.trim();
    final notes = _notesController.text.trim();

    final success = await ref.read(receivableProvider.notifier).addManualReceivable(
          customerName: customerName,
          amount: _amount,
          dueDate: _dueDate,
          notes: notes.isEmpty ? null : notes,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Piutang berhasil ditambahkan!'),
          backgroundColor: AppColors.primary,
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pop();
        }
      });
    } else {
      final errorMsg = ref.read(receivableProvider).value?.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg ?? 'Gagal menambahkan piutang'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final receivableState = ref.watch(receivableProvider);
    final isLoading = receivableState.value?.isLoading ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Piutang'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Catat Piutang Baru',
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Catat piutang/kasbon pelanggan secara manual (bukan dari transaksi kasir POS).',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Nama Pelanggan
              TextFormField(
                controller: _customerNameController,
                decoration: InputDecoration(
                  labelText: 'Nama Pelanggan (Wajib)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama pelanggan wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nominal Piutang
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                onChanged: _onAmountChanged,
                decoration: InputDecoration(
                  labelText: 'Nominal Piutang (Wajib)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixText: 'Rp',
                ),
                validator: (val) {
                  if (_amount <= 0) {
                    return 'Nominal piutang harus lebih dari 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Jatuh Tempo
              TextField(
                controller: _dueDateController,
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _dueDate = date;
                      _dueDateController.text = _formatDate(date);
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Jatuh Tempo (Opsional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _dueDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _dueDate = null;
                              _dueDateController.clear();
                            });
                          },
                        )
                      : const Icon(Icons.calendar_today, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              // Catatan
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Misal: Deskripsi pinjaman uang',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              FilledButton(
                onPressed: isLoading ? null : _saveReceivable,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Simpan Piutang'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

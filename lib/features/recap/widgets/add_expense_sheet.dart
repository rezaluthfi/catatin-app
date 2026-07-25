import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/router.dart';
import '../../../core/extensions/currency_extension.dart';
import '../../../data/models/operational_cost_model.dart';
import '../providers/recap_provider.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  const AddExpenseSheet({super.key, this.expense});

  final OperationalCostModel? expense;

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  int _amount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _descriptionController.text = widget.expense!.description;
      _amount = widget.expense!.amount;
      _amountController.text = widget.expense!.amount.toRupiahNoSymbol();
      _selectedDate = widget.expense!.date;
    }
    _dateController.text = _formatDate(_selectedDate);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
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

  void _submitExpense() async {
    if (!_formKey.currentState!.validate() || _amount <= 0) {
      return;
    }

    final success = widget.expense != null
        ? await ref.read(recapProvider.notifier).updateOperationalCost(
              widget.expense!.copyWith(
                description: _descriptionController.text.trim(),
                amount: _amount,
                date: _selectedDate,
              ),
            )
        : await ref.read(recapProvider.notifier).addOperationalCost(
              description: _descriptionController.text.trim(),
              amount: _amount,
              date: _selectedDate,
            );

    if (!mounted) return;

    if (success) {
      final router = GoRouter.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(widget.expense != null
              ? 'Pengeluaran berhasil diubah!'
              : 'Pengeluaran berhasil dicatat!'),
          backgroundColor: AppColors.primary,
          action: SnackBarAction(
            label: 'LIHAT',
            textColor: Colors.white,
            onPressed: () {
              router.go('${AppRoutes.recap}?tab=2');
            },
          ),
        ),
      );
    } else {
      final errorMsg = ref.read(recapProvider).value?.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg ?? (widget.expense != null
              ? 'Gagal mengubah pengeluaran'
              : 'Gagal mencatat pengeluaran')),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recapState = ref.watch(recapProvider);
    final isLoading = recapState.value?.isLoading ?? false;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.expense != null ? 'Edit Pengeluaran' : 'Catat Pengeluaran',
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Deskripsi pengeluaran
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Keterangan Pengeluaran (Wajib)',
                        hintText: 'Misal: Listrik bulanan, Bensin, Gaji karyawan',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Keterangan pengeluaran wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nominal pengeluaran
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      onChanged: _onAmountChanged,
                      decoration: InputDecoration(
                        labelText: 'Nominal Pengeluaran (Wajib)',
                        prefixText: 'Rp',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        if (_amount <= 0) {
                          return 'Nominal pengeluaran harus lebih dari 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tanggal Pengeluaran
                    TextField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                            _dateController.text = _formatDate(date);
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Tanggal Pengeluaran (Wajib)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: const Icon(Icons.calendar_today, size: 20),
                      ),
                    ),

                    const SizedBox(height: 28),

                    FilledButton(
                      onPressed: isLoading ? null : _submitExpense,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(widget.expense != null ? 'Simpan Perubahan' : 'Simpan Pengeluaran'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

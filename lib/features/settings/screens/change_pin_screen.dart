/// Layar Ganti PIN — alur 3 langkah:
///   1. Masukkan PIN lama (verifikasi)
///   2. Masukkan PIN baru
///   3. Konfirmasi PIN baru ? simpan
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/widgets/pin_dots_widget.dart';
import '../../../features/auth/widgets/pin_keypad_widget.dart';

enum _ChangePinStep { verifyOld, enterNew, confirmNew }

class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  static const int _pinMaxLength = 6;

  _ChangePinStep _step = _ChangePinStep.verifyOld;
  String _enteredPin = '';
  String _newPin = '';
  bool _isError = false;
  bool _isLoading = false;

  final GlobalKey<PinDotsWidgetState> _dotsKey = GlobalKey();

  String get _title {
    return switch (_step) {
      _ChangePinStep.verifyOld => 'Masukkan PIN Lama',
      _ChangePinStep.enterNew => 'Masukkan PIN Baru',
      _ChangePinStep.confirmNew => 'Konfirmasi PIN Baru',
    };
  }

  String get _subtitle {
    return switch (_step) {
      _ChangePinStep.verifyOld => 'Verifikasi identitas Anda terlebih dahulu',
      _ChangePinStep.enterNew => 'Buat PIN baru yang mudah diingat',
      _ChangePinStep.confirmNew => 'Masukkan ulang PIN baru Anda',
    };
  }

  void _onKeyPressed(String key) {
    if (_isLoading) return;
    if (key == 'del') {
      if (_enteredPin.isNotEmpty) {
        setState(() {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
          _isError = false;
        });
      }
      return;
    }
    if (_enteredPin.length >= _pinMaxLength) return;

    setState(() {
      _enteredPin += key;
      _isError = false;
    });

    if (_enteredPin.length == _pinMaxLength) {
      _handlePinComplete();
    }
  }

  Future<void> _handlePinComplete() async {
    switch (_step) {
      case _ChangePinStep.verifyOld:
        await _verifyOldPin();
      case _ChangePinStep.enterNew:
        _proceedToConfirm();
      case _ChangePinStep.confirmNew:
        await _saveNewPin();
    }
  }

  Future<void> _verifyOldPin() async {
    setState(() => _isLoading = true);
    final isCorrect =
        await ref.read(authProvider.notifier).verifyPin(_enteredPin);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (isCorrect) {
      setState(() {
        _step = _ChangePinStep.enterNew;
        _enteredPin = '';
        _isError = false;
      });
    } else {
      setState(() => _isError = true);
      _dotsKey.currentState?.shake();
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _enteredPin = '');
    }
  }

  void _proceedToConfirm() {
    setState(() {
      _newPin = _enteredPin;
      _step = _ChangePinStep.confirmNew;
      _enteredPin = '';
      _isError = false;
    });
  }

  Future<void> _saveNewPin() async {
    if (_enteredPin != _newPin) {
      setState(() => _isError = true);
      _dotsKey.currentState?.shake();
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _enteredPin = '';
          _isError = false;
        });
      }
      return;
    }

    setState(() => _isLoading = true);
    // changePin verifies old pin again internally — we skip that by calling
    // savePinHash directly via a dedicated notifier method.
    // We use resetPin (no-verify) since old PIN was already verified in step 1.
    await ref.read(authProvider.notifier).resetPin(_enteredPin);
    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PIN berhasil diubah!'),
        backgroundColor: AppColors.income,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ganti PIN'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: List.generate(3, (index) {
                  final stepIndex = _step.index;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: index <= stepIndex
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    _title,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _subtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Dots
                  PinDotsWidget(
                    key: _dotsKey,
                    filledCount: _enteredPin.length,
                    maxLength: _pinMaxLength,
                    isError: _isError,
                  ),
                  const SizedBox(height: 8),

                  // Error text
                  AnimatedOpacity(
                    opacity: _isError ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _step == _ChangePinStep.verifyOld
                          ? 'PIN lama salah, coba lagi'
                          : 'PIN tidak cocok, coba lagi',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.expense,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Keypad
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: PinKeypadWidget(
                  onDigitPressed: _onKeyPressed,
                  onBackspacePressed: () => _onKeyPressed('del'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

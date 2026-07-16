// PIN Lock Screen — ditampilkan setiap kali aplikasi dibuka.
// Pengguna harus memasukkan PIN 6 digit untuk membuka aplikasi.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../widgets/pin_dots_widget.dart';
import '../widgets/pin_keypad_widget.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  static const int _pinMaxLength = 6;

  String _enteredPin = '';
  bool _isError = false;
  bool _isSuccess = false;
  bool _isLoading = false;

  final GlobalKey<PinDotsWidgetState> _dotsKey = GlobalKey();

  // ─────────────────────────────────────────────────────────────
  // Handlers
  // ─────────────────────────────────────────────────────────────

  void _onDigitPressed(String digit) {
    if (_isLoading || _isSuccess || _enteredPin.length >= _pinMaxLength) return;
    setState(() {
      _isError = false;
      _enteredPin += digit;
    });
    // Auto-submit ketika sudah 6 digit
    if (_enteredPin.length == _pinMaxLength) {
      _verifyPin();
    }
  }

  void _onBackspacePressed() {
    if (_isLoading || _isSuccess || _enteredPin.isEmpty) return;
    setState(() {
      _isError = false;
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  Future<void> _verifyPin() async {
    if (_enteredPin.length < 4) return;
    setState(() => _isLoading = true);

    final isCorrect =
        await ref.read(authProvider.notifier).verifyPin(_enteredPin);

    if (!mounted) return;

    if (isCorrect) {
      setState(() {
        _isSuccess = true;
        _isLoading = false;
      });
      // Router akan otomatis redirect ke dashboard via RouterNotifier
    } else {
      HapticFeedback.vibrate();
      _dotsKey.currentState?.shake();
      setState(() {
        _isError = true;
        _isLoading = false;
        _enteredPin = '';
      });
    }
  }

  void _showForgotPinDialog(AuthState authState) {
    if (!authState.hasSecurityQuestion) {
      _showNoSecurityQuestionDialog();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _ForgotPinSheet(
        question: authState.securityQuestion ?? '',
      ),
    );
  }

  void _showNoSecurityQuestionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tidak Ada Pertanyaan Keamanan'),
        content: const Text(
          'Anda tidak mengatur pertanyaan keamanan saat pendaftaran PIN.\n\n'
          'Untuk mengatur ulang PIN, Anda harus menghapus dan menginstall ulang aplikasi.\n\n'
          'Catatan: Jika Anda memiliki file cadangan data (backup .json), Anda dapat memulihkan seluruh data Anda setelah menginstall ulang aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider).valueOrNull ?? const AuthState();
    final failedAttempts = authState.failedAttempts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Brand Area ──────────────────────────────────
            _buildTopArea(authState),

            const Spacer(),

            // ── PIN Input Area ──────────────────────────────────
            _buildPinArea(failedAttempts),

            const Spacer(),

            // ── Keypad ─────────────────────────────────────────
            PinKeypadWidget(
              onDigitPressed: _onDigitPressed,
              onBackspacePressed: _onBackspacePressed,
              enabled: !_isLoading && !_isSuccess,
            ),

            const SizedBox(height: 12),

            // ── Forgot PIN ─────────────────────────────────────
            TextButton(
              onPressed: () => _showForgotPinDialog(authState),
              child: Text(
                'Lupa PIN?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Icon(
                  Icons.copyright_rounded,
                  size: 13,
                  color: AppColors.textDisabled,
                ),
                SizedBox(width: 4),
                Text(
                  'KKN-PPM UGM Alor Carita 2026',
                  style: TextStyle(
                    fontFamily: 'GoogleSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildTopArea(AuthState authState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Logo image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/logo.jpeg',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          // App name
          Text(
            'CatatIn',
            style: AppTextStyles.displayMedium.copyWith(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            authState.businessName.isNotEmpty ? authState.businessName : ' ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withAlpha(200),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPinArea(int failedAttempts) {
    String hintText;
    if (_isSuccess) {
      hintText = 'PIN benar ✓';
    } else if (_isError) {
      hintText = failedAttempts >= 5
          ? 'Terlalu banyak percobaan. Gunakan "Lupa PIN?"'
          : 'PIN salah. Sisa ${5 - failedAttempts} percobaan';
    } else if (_isLoading) {
      hintText = 'Memverifikasi...';
    } else {
      hintText = 'Masukkan PIN Anda';
    }

    return Column(
      children: [
        PinDotsWidget(
          key: _dotsKey,
          filledCount: _enteredPin.length,
          maxLength: _pinMaxLength,
          isError: _isError,
          isSuccess: _isSuccess,
          dotSize: 18,
          spacing: 14,
        ),
        const SizedBox(height: 16),
        // Gunakan tinggi tetap 60px agar area status + loading stabil dan tidak menggeser posisi dots
        SizedBox(
          height: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  hintText,
                  key: ValueKey(hintText),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _isError
                        ? AppColors.expense
                        : _isSuccess
                            ? AppColors.income
                            : AppColors.textSecondary,
                    fontWeight:
                        _isError || _isSuccess ? FontWeight.w600 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 8),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Forgot PIN Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ForgotPinSheet extends ConsumerStatefulWidget {
  const _ForgotPinSheet({required this.question});

  final String question;

  @override
  ConsumerState<_ForgotPinSheet> createState() => _ForgotPinSheetState();
}

class _ForgotPinSheetState extends ConsumerState<_ForgotPinSheet> {
  final _answerController = TextEditingController();
  bool _isVerifyingAnswer = false;
  String _errorText = '';

  // State untuk PIN baru
  String _newPin = '';
  String _confirmPin = '';
  int _resetStep = 0; // 0: verif jawaban, 1: PIN baru, 2: konfirmasi PIN baru

  final GlobalKey<PinDotsWidgetState> _dotsKey = GlobalKey();

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _verifyAnswer() async {
    if (_answerController.text.trim().isEmpty) return;
    setState(() {
      _isVerifyingAnswer = true;
      _errorText = '';
    });

    final isCorrect = await ref
        .read(authProvider.notifier)
        .verifySecurityAnswer(_answerController.text.trim());

    if (!mounted) return;

    if (isCorrect) {
      setState(() {
        _isVerifyingAnswer = false;
        _resetStep = 1;
      });
    } else {
      setState(() {
        _errorText = 'Jawaban salah. Coba lagi.';
        _isVerifyingAnswer = false;
      });
    }
  }

  void _onDigitPressed(String digit) {
    if (_resetStep == 1) {
      if (_newPin.length >= 6) return;
      setState(() => _newPin += digit);
      if (_newPin.length == 6) {
        setState(() => _resetStep = 2);
      }
    } else if (_resetStep == 2) {
      if (_confirmPin.length >= 6) return;
      setState(() => _confirmPin += digit);
      if (_confirmPin.length == 6) {
        _doResetPin();
      }
    }
  }

  void _onBackspace() {
    if (_resetStep == 1 && _newPin.isNotEmpty) {
      setState(() => _newPin = _newPin.substring(0, _newPin.length - 1));
    } else if (_resetStep == 2 && _confirmPin.isNotEmpty) {
      setState(() => _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1));
    }
  }

  Future<void> _doResetPin() async {
    if (_newPin != _confirmPin) {
      _dotsKey.currentState?.shake();
      setState(() {
        _errorText = 'PIN tidak cocok. Coba lagi.';
        _confirmPin = '';
        _resetStep = 1;
        _newPin = '';
      });
      return;
    }
    await ref.read(authProvider.notifier).resetPin(_newPin);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            if (_resetStep == 0) ...[
              _buildAnswerStep(),
            ] else if (_resetStep == 1) ...[
              _buildNewPinStep(),
            ] else ...[
              _buildConfirmPinStep(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Reset PIN', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Jawab pertanyaan keamanan berikut:',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.question,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _answerController,
          decoration: InputDecoration(
            hintText: 'Jawaban kamu',
            errorText: _errorText.isNotEmpty ? _errorText : null,
          ),
          textCapitalization: TextCapitalization.none,
          onSubmitted: (_) => _verifyAnswer(),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isVerifyingAnswer ? null : _verifyAnswer,
            child: _isVerifyingAnswer
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Verifikasi Jawaban'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildNewPinStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Buat PIN Baru', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Masukkan PIN baru (6 digit)',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        PinDotsWidget(filledCount: _newPin.length),
        const SizedBox(height: 24),
        PinKeypadWidget(
          onDigitPressed: _onDigitPressed,
          onBackspacePressed: _onBackspace,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildConfirmPinStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Konfirmasi PIN Baru', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Masukkan kembali PIN baru kamu',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        PinDotsWidget(
          key: _dotsKey,
          filledCount: _confirmPin.length,
          isError: _errorText.isNotEmpty,
        ),
        if (_errorText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _errorText,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.expense),
          ),
        ],
        const SizedBox(height: 24),
        PinKeypadWidget(
          onDigitPressed: _onDigitPressed,
          onBackspacePressed: _onBackspace,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

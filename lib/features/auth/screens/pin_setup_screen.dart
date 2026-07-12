// PIN Setup Screen — onboarding pertama kali pengguna membuka aplikasi.
// Flow 4 langkah: (1) Profil Usaha → (2) Buat PIN → (3) Konfirmasi PIN → (4) Keamanan.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../widgets/pin_dots_widget.dart';
import '../widgets/pin_keypad_widget.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen>
    with SingleTickerProviderStateMixin {
  static const int _pinMaxLength = 6;
  static const int _totalSteps = 4;

  // ── State ─────────────────────────────────────────────────────
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Profil Usaha
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Step 2 & 3: PIN
  String _newPin = '';
  String _confirmPin = '';
  bool _isPinError = false;

  // Step 4: Keamanan
  String? _selectedQuestion;
  final _answerController = TextEditingController();
  bool _skipSecurity = false;

  final GlobalKey<PinDotsWidgetState> _dotsKey = GlobalKey();
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // Navigation
  // ─────────────────────────────────────────────────────────────

  void _nextStep() {
    _slideController.forward(from: 0);
    setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep == 0) return;
    _slideController.forward(from: 0);
    setState(() {
      _currentStep--;
      // Reset PIN state jika balik ke step PIN
      if (_currentStep == 1) {
        _newPin = '';
        _confirmPin = '';
        _isPinError = false;
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Step 1: Validasi Profil Usaha
  // ─────────────────────────────────────────────────────────────

  void _onStep1Next() {
    if (_formKey.currentState?.validate() ?? false) {
      _nextStep();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Step 2 & 3: PIN Input
  // ─────────────────────────────────────────────────────────────

  void _onDigitPressed(String digit) {
    setState(() => _isPinError = false);

    if (_currentStep == 1) {
      // Step 2: buat PIN baru
      if (_newPin.length >= _pinMaxLength) return;
      setState(() => _newPin += digit);
      if (_newPin.length == _pinMaxLength) {
        Future.delayed(const Duration(milliseconds: 200), _nextStep);
      }
    } else if (_currentStep == 2) {
      // Step 3: konfirmasi PIN
      if (_confirmPin.length >= _pinMaxLength) return;
      setState(() => _confirmPin += digit);
      if (_confirmPin.length == _pinMaxLength) {
        _validateConfirmPin();
      }
    }
  }

  void _onBackspace() {
    if (_currentStep == 1 && _newPin.isNotEmpty) {
      setState(() => _newPin = _newPin.substring(0, _newPin.length - 1));
    } else if (_currentStep == 2 && _confirmPin.isNotEmpty) {
      setState(() {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        _isPinError = false;
      });
    }
  }

  void _validateConfirmPin() {
    if (_newPin == _confirmPin) {
      Future.delayed(const Duration(milliseconds: 200), _nextStep);
    } else {
      _dotsKey.currentState?.shake();
      setState(() {
        _isPinError = true;
        _confirmPin = '';
      });
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Step 4: Simpan Setup
  // ─────────────────────────────────────────────────────────────

  Future<void> _onFinish() async {
    setState(() => _isLoading = true);

    await ref.read(authProvider.notifier).setupPin(
          pin: _newPin,
          businessName: _businessNameController.text.trim(),
          ownerName: _ownerNameController.text.trim(),
          securityQuestion: _skipSecurity ? null : _selectedQuestion,
          securityAnswer: _skipSecurity ? null : _answerController.text.trim(),
        );

    // Router otomatis redirect ke dashboard via RouterNotifier
    if (mounted) setState(() => _isLoading = false);
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────
            _buildHeader(),

            // ── Progress Bar ───────────────────────────────────
            _buildProgressBar(),

            // ── Step Content ────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_currentStep),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          // Tombol back (sembunyikan di step pertama)
          if (_currentStep > 0 && _currentStep < 3)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _prevStep,
            )
          else
            const SizedBox(width: 48),

          const Spacer(),

          // Logo
          Text(
            'Catatin',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),

          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            'Langkah ${_currentStep + 1} dari $_totalSteps',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1BusinessProfile();
      case 1:
        return _buildStep2CreatePin();
      case 2:
        return _buildStep3ConfirmPin();
      case 3:
        return _buildStep4Security();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Step 1: Profil Usaha
  // ─────────────────────────────────────────────────────────────

  Widget _buildStep1BusinessProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Selamat Datang! 👋', style: AppTextStyles.displayMedium),
            const SizedBox(height: 8),
            Text(
              'Pertama, ceritakan sedikit tentang usaha kamu.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Nama usaha
            Text(
              'Nama Usaha',
              style: AppTextStyles.labelMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _businessNameController,
              decoration: const InputDecoration(
                hintText: 'contoh: Warung Bu Sari',
                prefixIcon: Icon(Icons.store_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama usaha tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Nama pemilik
            Text(
              'Nama Pemilik',
              style: AppTextStyles.labelMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ownerNameController,
              decoration: const InputDecoration(
                hintText: 'contoh: Bu Sari',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama pemilik tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onStep1Next,
                child: const Text('Lanjutkan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Step 2: Buat PIN
  // ─────────────────────────────────────────────────────────────

  Widget _buildStep2CreatePin() {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Buat PIN Keamanan', style: AppTextStyles.headlineLarge),
                    const SizedBox(height: 8),
                    Text(
                      'PIN 6 digit untuk melindungi data keuangan kamu.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              PinDotsWidget(filledCount: _newPin.length),
              const Spacer(),
              PinKeypadWidget(
                onDigitPressed: _onDigitPressed,
                onBackspacePressed: _onBackspace,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Step 3: Konfirmasi PIN
  // ─────────────────────────────────────────────────────────────

  Widget _buildStep3ConfirmPin() {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Konfirmasi PIN', style: AppTextStyles.headlineLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Masukkan ulang PIN yang baru saja kamu buat.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              PinDotsWidget(
                key: _dotsKey,
                filledCount: _confirmPin.length,
                isError: _isPinError,
              ),
              const SizedBox(height: 8),
              AnimatedOpacity(
                opacity: _isPinError ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  'PIN tidak cocok. Coba lagi.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.expense),
                ),
              ),
              const Spacer(),
              PinKeypadWidget(
                onDigitPressed: _onDigitPressed,
                onBackspacePressed: _onBackspace,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Step 4: Pertanyaan Keamanan
  // ─────────────────────────────────────────────────────────────

  Widget _buildStep4Security() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Pertanyaan Keamanan 🔐', style: AppTextStyles.displayMedium),
          const SizedBox(height: 8),
          Text(
            'Digunakan untuk reset PIN jika kamu lupa. '
            'Sangat disarankan untuk diisi.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Pilih pertanyaan
          if (!_skipSecurity) ...[
            Text('Pilih Pertanyaan', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedQuestion,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.help_outline_rounded),
              ),
              hint: const Text('Pilih pertanyaan...'),
              isExpanded: true,
              itemHeight: null,
              items: AppConstants.securityQuestions.map((q) {
                return DropdownMenuItem(
                  value: q,
                  child: Text(
                    q,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedQuestion = val),
            ),
            const SizedBox(height: 16),

            Text('Jawaban', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _answerController,
              decoration: const InputDecoration(
                hintText: 'Jawaban kamu (tidak case-sensitive)',
                prefixIcon: Icon(Icons.short_text_rounded),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '* Jawaban tidak membedakan huruf besar/kecil.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Opsi lewati
          CheckboxListTile(
            value: _skipSecurity,
            onChanged: (val) =>
                setState(() => _skipSecurity = val ?? false),
            title: Text(
              'Lewati — saya tidak ingin mengatur pertanyaan keamanan',
              style: AppTextStyles.bodySmall,
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),

          if (_skipSecurity)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tanpa pertanyaan keamanan, PIN tidak bisa direset jika lupa.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      final canFinish = _skipSecurity ||
                          (_selectedQuestion != null &&
                              _answerController.text.trim().isNotEmpty);
                      if (!canFinish) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Pilih pertanyaan dan isi jawaban, atau centang "Lewati".',
                            ),
                          ),
                        );
                        return;
                      }
                      _onFinish();
                    },
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Mulai Gunakan Catatin'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

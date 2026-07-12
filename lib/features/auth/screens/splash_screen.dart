import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

/// Provider sederhana untuk mengontrol durasi tayang splash screen.
/// Bernilai true saat splash aktif, dan menjadi false setelah animasi selesai.
final showSplashProvider = StateProvider<bool>((ref) => true);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Jalankan timer untuk beralih layar setelah 2.5 detik
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        ref.read(showSplashProvider.notifier).state = false;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Logo & Judul di Tengah
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo dari Assets
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/images/logo.jpeg',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Nama Aplikasi
                        Text(
                          'Catatin',
                          style: AppTextStyles.headingLarge.copyWith(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Subtitle
                        Text(
                          'Pencatatan Keuangan Praktis & Aman',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Versi di Bawah
              Positioned(
                bottom: 48,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'v1.0.0',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.4),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

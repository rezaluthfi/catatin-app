// Widget indikator PIN — menampilkan titik-titik yang terisi sesuai digit yang dimasukkan.
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// Menampilkan baris dot (titik) sebagai indikator PIN yang sedang dimasukkan.
///
/// Dot yang sudah terisi berwarna brand green, yang kosong hanya outline.
/// Animasi shake bisa dipicu dari luar melalui [GlobalKey<PinDotsWidgetState>].
class PinDotsWidget extends StatefulWidget {
  const PinDotsWidget({
    super.key,
    required this.filledCount,
    this.maxLength = 6,
    this.isError = false,
    this.isSuccess = false,
    this.dotSize = 16.0,
    this.spacing = 16.0,
  });

  /// Jumlah digit yang sudah dimasukkan (dot terisi).
  final int filledCount;

  /// Panjang PIN maksimum (jumlah dot yang ditampilkan).
  final int maxLength;

  /// Tampilkan dot dalam warna error (merah) — untuk PIN salah.
  final bool isError;

  /// Tampilkan dot dalam warna success (hijau lebih cerah) — untuk PIN benar.
  final bool isSuccess;

  final double dotSize;
  final double spacing;

  @override
  State<PinDotsWidget> createState() => PinDotsWidgetState();
}

class PinDotsWidgetState extends State<PinDotsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    // TweenSequence menghasilkan nilai offset pixel secara langsung:
    // 0 → +10 → -10 → +10 → -10 → 0 (kembali ke posisi awal)
    // Ini adalah pola yang benar untuk shake — tidak menggunakan CurvedAnimation
    // karena Flutter mensyaratkan curve.transform(1.0) == ~1.0, sedangkan
    // shake harus berakhir di 0.0.
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  /// Panggil untuk memicu animasi shake (saat PIN salah).
  void shake() {
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          // _shakeAnimation.value sudah berupa offset pixel dari TweenSequence
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.maxLength, (index) {
          final isFilled = index < widget.filledCount;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
            width: widget.dotSize,
            height: widget.dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getDotColor(isFilled),
              border: Border.all(
                color: _getBorderColor(isFilled),
                width: 2,
              ),
            ),
          );
        }),
      ),
    );
  }

  Color _getDotColor(bool isFilled) {
    if (!isFilled) return Colors.transparent;
    if (widget.isError) return AppColors.expense;
    if (widget.isSuccess) return AppColors.income;
    return AppColors.primary;
  }

  Color _getBorderColor(bool isFilled) {
    if (widget.isError) return AppColors.expense;
    if (widget.isSuccess) return AppColors.income;
    if (isFilled) return AppColors.primary;
    return AppColors.border;
  }
}


// Widget keypad numpad untuk input PIN.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

/// Keypad numerik (0-9) dengan tombol backspace untuk input PIN.
///
/// Layout:
/// ```
/// [ 1 ] [ 2 ] [ 3 ]
/// [ 4 ] [ 5 ] [ 6 ]
/// [ 7 ] [ 8 ] [ 9 ]
/// [   ] [ 0 ] [ ⌫ ]
/// ```
///
/// Slot kiri-bawah bisa diisi widget custom via [bottomLeftChild].
class PinKeypadWidget extends StatefulWidget {
  const PinKeypadWidget({
    super.key,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    this.bottomLeftChild,
    this.keySize,
    this.enabled = true,
  });

  /// Dipanggil saat tombol angka ditekan, dengan argumen digit ('0'–'9').
  final void Function(String digit) onDigitPressed;

  /// Dipanggil saat tombol backspace ditekan.
  final VoidCallback onBackspacePressed;

  /// Widget opsional di slot kiri-bawah (misal: tombol "Lupa PIN" atau ikon).
  final Widget? bottomLeftChild;

  /// Ukuran (diameter) setiap tombol angka. Jika null, otomatis menyesuaikan tinggi layar.
  final double? keySize;

  /// Jika false, semua tombol tidak bisa ditekan.
  final bool enabled;

  @override
  State<PinKeypadWidget> createState() => _PinKeypadWidgetState();
}

class _PinKeypadWidgetState extends State<PinKeypadWidget> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!widget.enabled || event is! KeyDownEvent) return false;

    if (event.logicalKey == LogicalKeyboardKey.backspace ||
        event.logicalKey == LogicalKeyboardKey.delete) {
      widget.onBackspacePressed();
      return true;
    }

    final char = event.character;
    if (char != null && RegExp(r'^[0-9]$').hasMatch(char)) {
      widget.onDigitPressed(char);
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.numpad0) {
      widget.onDigitPressed('0');
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.numpad1) {
      widget.onDigitPressed('1');
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.numpad2) {
      widget.onDigitPressed('2');
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.numpad3) {
      widget.onDigitPressed('3');
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.numpad4) {
      widget.onDigitPressed('4');
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.numpad5) {
      widget.onDigitPressed('5');
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.numpad6) {
      widget.onDigitPressed('6');
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.numpad7) {
      widget.onDigitPressed('7');
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.numpad8) {
      widget.onDigitPressed('8');
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.numpad9) {
      widget.onDigitPressed('9');
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double activeKeySize =
        widget.keySize ?? (screenHeight < 680 ? 56.0 : 72.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['1', '2', '3'], activeKeySize),
        const SizedBox(height: 12),
        _buildRow(['4', '5', '6'], activeKeySize),
        const SizedBox(height: 12),
        _buildRow(['7', '8', '9'], activeKeySize),
        const SizedBox(height: 12),
        _buildBottomRow(activeKeySize),
      ],
    );
  }

  Widget _buildRow(List<String> digits, double activeKeySize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((d) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _DigitKey(
            digit: d,
            size: activeKeySize,
            enabled: widget.enabled,
            onPressed: () => widget.onDigitPressed(d),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomRow(double activeKeySize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Slot kiri bawah — bisa diisi widget custom atau kosong
        SizedBox(
          width: activeKeySize + 32,
          height: activeKeySize,
          child: widget.bottomLeftChild != null
              ? Center(child: widget.bottomLeftChild)
              : const SizedBox.shrink(),
        ),

        // Angka 0
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _DigitKey(
            digit: '0',
            size: activeKeySize,
            enabled: widget.enabled,
            onPressed: () => widget.onDigitPressed('0'),
          ),
        ),

        // Tombol backspace
        SizedBox(
          width: activeKeySize + 32,
          height: activeKeySize,
          child: Center(
            child: _BackspaceKey(
              size: activeKeySize,
              enabled: widget.enabled,
              onPressed: widget.onBackspacePressed,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Digit Key Widget
// ─────────────────────────────────────────────────────────────────────────────

class _DigitKey extends StatefulWidget {
  const _DigitKey({
    required this.digit,
    required this.size,
    required this.onPressed,
    this.enabled = true,
  });

  final String digit;
  final double size;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  State<_DigitKey> createState() => _DigitKeyState();
}

class _DigitKeyState extends State<_DigitKey>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handlePress() {
    if (!widget.enabled) return;
    HapticFeedback.lightImpact();
    _pressController.forward().then((_) {
      _pressController.reverse();
    });
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _handlePress,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withAlpha(20),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.digit,
              style: AppTextStyles.displayMedium.copyWith(
                fontSize: 26,
                color: widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.textDisabled,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Backspace Key Widget
// ─────────────────────────────────────────────────────────────────────────────

class _BackspaceKey extends StatelessWidget {
  const _BackspaceKey({
    required this.size,
    required this.onPressed,
    this.enabled = true,
  });

  final double size;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onPressed();
            }
          : null,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            size: 26,
            color: enabled ? AppColors.textSecondary : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}

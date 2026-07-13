/// Definisi tipografi (text styles) untuk seluruh aplikasi Catatin.
///
/// Menggunakan custom font 'GoogleSans' yang dilampirkan via assets/fonts.
/// fontFamily diset di setiap style agar .copyWith() tetap mewarisi font
/// meski digunakan di luar konteks ThemeData.
import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._(); // Prevent instantiation

  static const String _fontFamily = 'GoogleSans';

  // --- Display ---
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.25,
  );

  // --- Heading ---
  static const TextStyle headingLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static const TextStyle headingSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // --- Body ---
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // --- Label ---
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textDisabled,
    letterSpacing: 0.5,
  );

  // --- Headline aliases (Material 3 naming untuk konsistensi dengan screen) ---
  static const TextStyle headlineLarge = headingLarge;
  static const TextStyle headlineMedium = headingMedium;
  static const TextStyle headlineSmall = headingSmall;

  // --- Angka Keuangan (khusus untuk nominal Rupiah) ---
  static const TextStyle currencyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle currencyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle currencySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // --- Nuanced Variants ---
  static TextStyle get bodyMediumSecondary =>
      bodyMedium.copyWith(color: AppColors.textSecondary);

  static TextStyle get bodySmallIncome =>
      bodySmall.copyWith(color: AppColors.income, fontWeight: FontWeight.w600);

  static TextStyle get bodySmallExpense =>
      bodySmall.copyWith(color: AppColors.expense, fontWeight: FontWeight.w600);
}

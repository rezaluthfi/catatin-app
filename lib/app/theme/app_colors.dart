/// Konstanta warna untuk seluruh aplikasi Catatin.
///
/// Semua warna didefinisikan di sini agar perubahan tema cukup dilakukan
/// di satu tempat (single source of truth).
import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Prevent instantiation

  // --- Brand Colors ---
  static const Color primary = Color(0xFF1A7A4A);       // Hijau tua (kepercayaan & uang)
  static const Color primaryLight = Color(0xFF4CAF7D);  // Hijau muda
  static const Color primaryDark = Color(0xFF0D5C37);   // Hijau gelap

  static const Color secondary = Color(0xFFE8A020);     // Kuning emas (aksen)
  static const Color secondaryLight = Color(0xFFF5C552);
  static const Color secondaryDark = Color(0xFFB87A10);

  // --- Neutral Colors ---
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F2F5);

  static const Color textPrimary = Color(0xFF1A1D23);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFFB0B7C3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // --- Semantic Colors ---
  static const Color income = Color(0xFF1A7A4A);   // Kas masuk → hijau
  static const Color expense = Color(0xFFE53E3E);  // Kas keluar → merah
  static const Color warning = Color(0xFFE8A020);  // Peringatan stok → kuning
  static const Color info = Color(0xFF3B82F6);     // Informasi → biru

  // --- Container Colors (background tint untuk area semantic) ---
  static const Color primaryContainer = Color(0xFFDFF2E9);  // Hijau muda pudar
  static const Color warningContainer = Color(0xFFFFF8E7);  // Kuning muda pudar
  static const Color errorContainer = Color(0xFFFEECEC);    // Merah muda pudar
  static const Color infoContainer = Color(0xFFEFF6FF);     // Biru muda pudar

  // --- Border & Divider ---
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF0F2F5);

  // --- Overlay ---
  static const Color overlay = Color(0x80000000); // 50% hitam
  static const Color shimmer = Color(0xFFE8ECF0);
}

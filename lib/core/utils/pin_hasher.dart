// Utilitas hashing PIN menggunakan SHA-256.
//
// PIN tidak pernah disimpan sebagai teks biasa — hanya hash-nya yang disimpan
// di flutter_secure_storage. Salt ditambahkan untuk mencegah rainbow table attack.
import 'dart:convert';

import 'package:crypto/crypto.dart';

class PinHasher {
  PinHasher._(); // Prevent instantiation

  /// Salt unik untuk aplikasi ini.
  static const String _salt = 'catatin_ugm_kkn_2026_secure';

  /// Hash input (PIN atau jawaban keamanan) dengan SHA-256 + salt.
  static String hash(String input) {
    final bytes = utf8.encode('$_salt:$input');
    return sha256.convert(bytes).toString();
  }

  /// Verifikasi apakah [input] cocok dengan [storedHash].
  static bool verify(String input, String storedHash) {
    return hash(input) == storedHash;
  }

  /// Hash jawaban pertanyaan keamanan.
  /// Jawaban di-normalize (lowercase + trim) sebelum di-hash
  /// agar tidak case-sensitive saat verifikasi.
  static String hashSecurityAnswer(String answer) {
    return hash(answer.toLowerCase().trim());
  }
}

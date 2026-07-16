import 'dart:convert';

/// Model data untuk Pengaturan Aplikasi.
///
/// Data pengaturan disimpan sebagai key-value pairs di tabel `settings`.
/// [SettingsModel] meng-aggregate semua key tersebut menjadi satu object.
class SettingsModel {
  const SettingsModel({
    this.businessName = '',
    this.ownerName = '',
    this.defaultMargin = 30,
    this.pinHash,
    this.securityQuestion,
    this.securityAnswerHash,
    this.bankAccounts = const [],
  });

  final String businessName;
  final String ownerName;
  final int defaultMargin;

  /// Hash PIN (tersimpan via flutter_secure_storage, bukan di SQLite).
  final String? pinHash;

  /// Pertanyaan keamanan untuk reset PIN.
  final String? securityQuestion;

  /// Hash jawaban pertanyaan keamanan.
  final String? securityAnswerHash;

  /// Daftar rekening bank / e-wallet terdaftar.
  final List<String> bankAccounts;

  // ─────────────────────────────────────────────────────────────
  // Computed properties
  // ─────────────────────────────────────────────────────────────

  /// Apakah PIN sudah di-setup?
  bool get hasPinSetup => pinHash != null && pinHash!.isNotEmpty;

  /// Apakah pertanyaan keamanan sudah di-setup?
  bool get hasSecurityQuestion =>
      securityQuestion != null && securityQuestion!.isNotEmpty;

  // ─────────────────────────────────────────────────────────────
  // Conversion
  // ─────────────────────────────────────────────────────────────

  /// Buat dari Map key-value (hasil query dari tabel settings).
  factory SettingsModel.fromMap(Map<String, String> map) {
    List<String> accounts = [];
    final jsonStr = map['bank_accounts'];
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        accounts = decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    return SettingsModel(
      businessName: map['business_name'] ?? '',
      ownerName: map['owner_name'] ?? '',
      defaultMargin: int.tryParse(map['default_margin'] ?? '') ?? 30,
      pinHash: map['pin_hash'],
      securityQuestion: map['security_question'],
      securityAnswerHash: map['security_answer_hash'],
      bankAccounts: accounts,
    );
  }

  /// Konversi ke Map key-value untuk disimpan ke database.
  Map<String, String> toMap() {
    final map = <String, String>{
      'business_name': businessName,
      'owner_name': ownerName,
      'default_margin': defaultMargin.toString(),
      'bank_accounts': jsonEncode(bankAccounts),
    };
    if (pinHash != null) map['pin_hash'] = pinHash!;
    if (securityQuestion != null) map['security_question'] = securityQuestion!;
    if (securityAnswerHash != null) {
      map['security_answer_hash'] = securityAnswerHash!;
    }
    return map;
  }

  SettingsModel copyWith({
    String? businessName,
    String? ownerName,
    int? defaultMargin,
    String? pinHash,
    String? securityQuestion,
    String? securityAnswerHash,
    List<String>? bankAccounts,
  }) {
    return SettingsModel(
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      defaultMargin: defaultMargin ?? this.defaultMargin,
      pinHash: pinHash ?? this.pinHash,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      securityAnswerHash: securityAnswerHash ?? this.securityAnswerHash,
      bankAccounts: bankAccounts ?? this.bankAccounts,
    );
  }

  @override
  String toString() =>
      'SettingsModel(businessName: $businessName, ownerName: $ownerName, defaultMargin: $defaultMargin, bankAccounts: $bankAccounts)';
}

/// Model data untuk Pengaturan Aplikasi.
///
/// Data pengaturan disimpan sebagai key-value pairs di tabel `settings`.
/// [SettingsModel] meng-aggregate semua key tersebut menjadi satu object.
class SettingsModel {
  const SettingsModel({
    this.businessName = '',
    this.ownerName = '',
    this.pinHash,
    this.securityQuestion,
    this.securityAnswerHash,
  });

  final String businessName;
  final String ownerName;

  /// Hash PIN (tersimpan via flutter_secure_storage, bukan di SQLite).
  final String? pinHash;

  /// Pertanyaan keamanan untuk reset PIN.
  final String? securityQuestion;

  /// Hash jawaban pertanyaan keamanan.
  final String? securityAnswerHash;

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
    return SettingsModel(
      businessName: map['business_name'] ?? '',
      ownerName: map['owner_name'] ?? '',
      pinHash: map['pin_hash'],
      securityQuestion: map['security_question'],
      securityAnswerHash: map['security_answer_hash'],
    );
  }

  /// Konversi ke Map key-value untuk disimpan ke database.
  Map<String, String> toMap() {
    final map = <String, String>{
      'business_name': businessName,
      'owner_name': ownerName,
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
    String? pinHash,
    String? securityQuestion,
    String? securityAnswerHash,
  }) {
    return SettingsModel(
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      pinHash: pinHash ?? this.pinHash,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      securityAnswerHash: securityAnswerHash ?? this.securityAnswerHash,
    );
  }

  @override
  String toString() =>
      'SettingsModel(businessName: $businessName, ownerName: $ownerName)';
}

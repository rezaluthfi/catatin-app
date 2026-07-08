// State untuk fitur autentikasi PIN.

/// Status autentikasi aplikasi.
enum AuthStatus {
  /// Sedang memuat data dari storage (state awal).
  loading,

  /// Pertama kali buka aplikasi, PIN belum pernah dibuat.
  firstRun,

  /// PIN sudah dibuat tapi belum dimasukkan sesi ini.
  locked,

  /// PIN sudah diverifikasi, pengguna dapat mengakses aplikasi.
  authenticated,
}

/// State lengkap untuk AuthNotifier.
class AuthState {
  const AuthState({
    this.status = AuthStatus.loading,
    this.businessName = '',
    this.failedAttempts = 0,
    this.hasSecurityQuestion = false,
    this.securityQuestion,
  });

  final AuthStatus status;

  /// Nama usaha — ditampilkan di PIN lock screen.
  final String businessName;

  /// Jumlah percobaan PIN yang salah sesi ini.
  final int failedAttempts;

  /// Apakah pertanyaan keamanan sudah disetup?
  final bool hasSecurityQuestion;

  /// Pertanyaan keamanan yang dipilih saat setup.
  final String? securityQuestion;

  // ─── Computed Properties ────────────────────────────────────
  bool get isLoading => status == AuthStatus.loading;
  bool get isFirstRun => status == AuthStatus.firstRun;
  bool get isLocked => status == AuthStatus.locked;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Setelah 5x salah, minta jawaban keamanan sebagai fallback.
  bool get isMaxAttemptsReached => failedAttempts >= 5;

  AuthState copyWith({
    AuthStatus? status,
    String? businessName,
    int? failedAttempts,
    bool? hasSecurityQuestion,
    String? securityQuestion,
  }) {
    return AuthState(
      status: status ?? this.status,
      businessName: businessName ?? this.businessName,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      hasSecurityQuestion: hasSecurityQuestion ?? this.hasSecurityQuestion,
      securityQuestion: securityQuestion ?? this.securityQuestion,
    );
  }

  @override
  String toString() =>
      'AuthState(status: $status, failedAttempts: $failedAttempts)';
}

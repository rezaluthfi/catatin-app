// Provider untuk repository settings dan state manajemen autentikasi.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/pin_hasher.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../domain/repositories/i_settings_repository.dart';
import 'auth_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Provider untuk SettingsRepository.
/// Didefinisikan di sini karena digunakan oleh AuthNotifier.
/// Fitur lain yang butuh settings akan import dari sini.
final settingsRepositoryProvider = Provider<ISettingsRepository>((ref) {
  return SettingsRepository();
});

// ─────────────────────────────────────────────────────────────────────────────
// Auth Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Provider utama untuk state autentikasi PIN.
///
/// Gunakan [ref.watch(authProvider)] untuk membaca state.
/// Gunakan [ref.read(authProvider.notifier)] untuk memanggil aksi.
final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Mengelola seluruh logika autentikasi PIN aplikasi Catatin.
class AuthNotifier extends AsyncNotifier<AuthState> {
  late ISettingsRepository _settingsRepo;

  @override
  Future<AuthState> build() async {
    _settingsRepo = ref.read(settingsRepositoryProvider);
    return _loadInitialState();
  }

  // ─────────────────────────────────────────────────────────────
  // Inisialisasi
  // ─────────────────────────────────────────────────────────────

  /// Cek apakah PIN sudah pernah dibuat (untuk menentukan first run atau locked).
  Future<AuthState> _loadInitialState() async {
    final pinHash = await _settingsRepo.getPinHash();

    if (pinHash == null || pinHash.isEmpty) {
      // PIN belum pernah dibuat → tampilkan setup
      return const AuthState(status: AuthStatus.firstRun);
    }

    // PIN sudah ada → load info untuk lock screen
    final settings = await _settingsRepo.getSettings();
    return AuthState(
      status: AuthStatus.locked,
      businessName: settings.businessName,
      hasSecurityQuestion: settings.hasSecurityQuestion,
      securityQuestion: settings.securityQuestion,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Aksi Autentikasi
  // ─────────────────────────────────────────────────────────────

  /// Verifikasi PIN yang dimasukkan pengguna.
  /// Kembalikan true jika PIN benar, false jika salah.
  Future<bool> verifyPin(String pin) async {
    final currentState = state.valueOrNull ?? const AuthState();

    final storedHash = await _settingsRepo.getPinHash();
    if (storedHash == null || storedHash.isEmpty) return false;

    final isCorrect = PinHasher.verify(pin, storedHash);

    if (isCorrect) {
      state = AsyncValue.data(
        currentState.copyWith(
          status: AuthStatus.authenticated,
          failedAttempts: 0,
        ),
      );
      return true;
    } else {
      state = AsyncValue.data(
        currentState.copyWith(
          failedAttempts: currentState.failedAttempts + 1,
        ),
      );
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Setup Pertama Kali
  // ─────────────────────────────────────────────────────────────

  /// Simpan PIN baru saat setup awal.
  /// Dipanggil setelah pengguna mengkonfirmasi PIN di setup screen.
  Future<void> setupPin({
    required String pin,
    String? businessName,
    String? ownerName,
    String? securityQuestion,
    String? securityAnswer,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Simpan PIN hash ke secure storage
      await _settingsRepo.savePinHash(PinHasher.hash(pin));

      // Simpan info usaha jika ada
      if (businessName != null && businessName.isNotEmpty) {
        await _settingsRepo.saveBusinessName(businessName);
      }
      if (ownerName != null && ownerName.isNotEmpty) {
        await _settingsRepo.saveOwnerName(ownerName);
      }

      // Simpan pertanyaan keamanan jika diisi
      if (securityQuestion != null &&
          securityAnswer != null &&
          securityAnswer.isNotEmpty) {
        await _settingsRepo.saveSecurityInfo(
          question: securityQuestion,
          answerHash: PinHasher.hashSecurityAnswer(securityAnswer),
        );
      }

      state = AsyncValue.data(
        AuthState(
          status: AuthStatus.authenticated,
          businessName: businessName ?? '',
          hasSecurityQuestion: securityQuestion != null,
          securityQuestion: securityQuestion,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Reset PIN via Pertanyaan Keamanan
  // ─────────────────────────────────────────────────────────────

  /// Verifikasi jawaban pertanyaan keamanan.
  Future<bool> verifySecurityAnswer(String answer) async {
    final answerHash = PinHasher.hashSecurityAnswer(answer);
    return _settingsRepo.verifySecurityAnswer(answerHash);
  }

  /// Reset PIN setelah jawaban keamanan berhasil diverifikasi.
  Future<void> resetPin(String newPin) async {
    await _settingsRepo.savePinHash(PinHasher.hash(newPin));

    final currentState = state.valueOrNull ?? const AuthState();
    state = AsyncValue.data(
      currentState.copyWith(
        status: AuthStatus.authenticated,
        failedAttempts: 0,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Ganti PIN (dari Settings)
  // ─────────────────────────────────────────────────────────────

  /// Ganti PIN setelah pengguna memasukkan PIN lama yang benar.
  Future<bool> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    final isOldPinCorrect = await verifyPin(oldPin);
    if (!isOldPinCorrect) return false;

    await _settingsRepo.savePinHash(PinHasher.hash(newPin));
    return true;
  }

  // ─────────────────────────────────────────────────────────────
  // Lock / Reload
  // ─────────────────────────────────────────────────────────────

  /// Kunci aplikasi (misal saat app masuk background).
  void lock() {
    final currentState = state.valueOrNull ?? const AuthState();
    state = AsyncValue.data(
      currentState.copyWith(status: AuthStatus.locked, failedAttempts: 0),
    );
  }

  /// Reload state dari awal (untuk hot restart).
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _loadInitialState());
  }
}

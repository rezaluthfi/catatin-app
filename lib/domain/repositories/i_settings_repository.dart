/// Interface (kontrak) untuk repository Pengaturan.
import '../../data/models/settings_model.dart';

abstract interface class ISettingsRepository {
  /// Ambil semua pengaturan aplikasi.
  Future<SettingsModel> getSettings();

  /// Simpan nama usaha.
  Future<void> saveBusinessName(String name);

  /// Simpan nama pemilik.
  Future<void> saveOwnerName(String name);

  /// Simpan margin keuntungan default.
  Future<void> saveDefaultMargin(int margin);

  /// Simpan daftar rekening / e-wallet.
  Future<void> saveBankAccounts(List<String> bankAccounts);

  /// Simpan hash PIN (melalui flutter_secure_storage).
  Future<void> savePinHash(String pinHash);

  /// Ambil hash PIN tersimpan.
  Future<String?> getPinHash();

  /// Simpan pertanyaan & jawaban keamanan untuk reset PIN.
  Future<void> saveSecurityInfo({
    required String question,
    required String answerHash,
  });

  /// Verifikasi jawaban keamanan. Kembalikan true jika cocok.
  Future<bool> verifySecurityAnswer(String answerHash);

  /// Ekspor semua data ke format JSON string.
  Future<String> exportToJson();

  /// Import data dari JSON string (mengganti semua data yang ada).
  Future<void> importFromJson(String jsonString);
}

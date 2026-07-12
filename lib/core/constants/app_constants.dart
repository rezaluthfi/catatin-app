/// Konstanta umum yang digunakan di seluruh aplikasi Catatin.
class AppConstants {
  AppConstants._(); // Prevent instantiation

  // --- App Info ---
  static const String appName = 'Catatin';
  static const String appVersion = '1.0.0';
  static const String appDeveloper =
      'Dikembangkan oleh Tim KKN-PPM UGM Alor Carita 2026';

  // --- PIN ---
  static const int pinMinLength = 4;
  static const int pinMaxLength = 6;

  // --- Stok ---
  static const int lowStockThreshold = 5; // Peringatan stok menipis

  // --- Pagination ---
  static const int defaultPageSize = 20;

  // --- Format Tanggal ---
  static const String dateFormatDisplay = 'dd MMMM yyyy';
  static const String dateFormatShort = 'dd/MM/yyyy';
  static const String timeFormatDisplay = 'HH:mm';
  static const String dateTimeFormatDb = "yyyy-MM-dd'T'HH:mm:ss";

  // --- Currency ---
  static const String currencySymbol = 'Rp';
  static const String currencyLocale = 'id_ID';

  // --- Shared Preferences / Secure Storage Keys ---
  static const String keyPinHash = 'pin_hash';
  static const String keyBusinessName = 'business_name';
  static const String keyOwnerName = 'owner_name';
  static const String keySecurityQuestion = 'security_question';
  static const String keySecurityAnswerHash = 'security_answer_hash';
  static const String keyIsFirstRun = 'is_first_run';
  static const String keyDefaultMargin = 'default_margin';

  // --- Export / Import ---
  static const String exportFileName = 'catatin_backup';
  static const String exportFileExtension = '.json';

  // --- Pertanyaan Keamanan untuk Reset PIN ---
  static const List<String> securityQuestions = [
    'Apa nama ibu kandung Anda?',
    'Apa nama kota kelahiran Anda?',
    'Apa nama hewan peliharaan pertama Anda?',
    'Apa nama sekolah dasar Anda?',
  ];
}

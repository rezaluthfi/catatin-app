/// State untuk fitur Pengaturan.
class SettingsState {
  const SettingsState({
    this.businessName = '',
    this.ownerName = '',
    this.defaultMargin = 30,
    this.securityQuestion,
    this.hasSecurityQuestion = false,
    this.isExporting = false,
    this.isImporting = false,
    this.exportError,
    this.importError,
    this.bankAccounts = const [],
  });

  final String businessName;
  final String ownerName;
  final int defaultMargin;
  final String? securityQuestion;
  final bool hasSecurityQuestion;
  final bool isExporting;
  final bool isImporting;
  final String? exportError;
  final String? importError;
  final List<String> bankAccounts;

  SettingsState copyWith({
    String? businessName,
    String? ownerName,
    int? defaultMargin,
    String? securityQuestion,
    bool? hasSecurityQuestion,
    bool? isExporting,
    bool? isImporting,
    String? exportError,
    String? importError,
    List<String>? bankAccounts,
  }) {
    return SettingsState(
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      defaultMargin: defaultMargin ?? this.defaultMargin,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      hasSecurityQuestion: hasSecurityQuestion ?? this.hasSecurityQuestion,
      isExporting: isExporting ?? this.isExporting,
      isImporting: isImporting ?? this.isImporting,
      exportError: exportError,
      importError: importError,
      bankAccounts: bankAccounts ?? this.bankAccounts,
    );
  }
}

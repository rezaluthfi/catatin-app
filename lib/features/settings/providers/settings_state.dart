/// State untuk fitur Pengaturan.
class SettingsState {
  const SettingsState({
    this.businessName = '',
    this.ownerName = '',
    this.defaultMargin = 30,
    this.isExporting = false,
    this.isImporting = false,
    this.exportError,
    this.importError,
  });

  final String businessName;
  final String ownerName;
  final int defaultMargin;
  final bool isExporting;
  final bool isImporting;
  final String? exportError;
  final String? importError;

  SettingsState copyWith({
    String? businessName,
    String? ownerName,
    int? defaultMargin,
    bool? isExporting,
    bool? isImporting,
    String? exportError,
    String? importError,
  }) {
    return SettingsState(
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      defaultMargin: defaultMargin ?? this.defaultMargin,
      isExporting: isExporting ?? this.isExporting,
      isImporting: isImporting ?? this.isImporting,
      exportError: exportError,
      importError: importError,
    );
  }
}

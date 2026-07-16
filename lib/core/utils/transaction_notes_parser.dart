class TransactionNotesParser {
  TransactionNotesParser._();

  /// Mengambil detail pembayaran non-tunai dari dalam kurung siku.
  /// Contoh: "[Transfer - Bank Mandiri] Catatan" -> "Transfer - Bank Mandiri"
  static String? getPaymentDetail(String? notes) {
    if (notes == null) return null;
    final match = RegExp(r'^\[(.*?)\]').firstMatch(notes);
    return match?.group(1);
  }

  /// Mengambil catatan kustom asli dari user setelah bagian detail pembayaran.
  /// Contoh: "[Transfer - Bank Mandiri] Catatan kustom" -> "Catatan kustom"
  static String? getCustomNotes(String? notes) {
    if (notes == null) return null;
    final paymentDetail = getPaymentDetail(notes);
    if (paymentDetail != null) {
      final prefixLength = paymentDetail.length + 2; // +2 untuk '[' dan ']'
      if (notes.length > prefixLength) {
        return notes.substring(prefixLength).trim();
      }
      return null;
    }
    return notes;
  }
}

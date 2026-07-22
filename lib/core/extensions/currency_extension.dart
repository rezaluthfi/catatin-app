/// Extension pada [int] untuk format mata uang Rupiah.
///
/// Penggunaan:
/// ```dart
/// final price = 15000;
/// print(price.toRupiah()); // → 'Rp15.000'
/// print(price.toRupiahCompact()); // → 'Rp15rb'
/// ```
import 'package:intl/intl.dart';

extension CurrencyExtension on int {
  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static final _formatterNoSymbol = NumberFormat('#,###', 'id_ID');

  /// Format ke Rupiah penuh: `Rp15.000`
  String toRupiah() => _formatter.format(this);

  /// Format angka saja tanpa simbol: `15.000`
  String toRupiahNoSymbol() => _formatterNoSymbol.format(this);

  /// Format compact untuk angka besar: `Rp15rb`, `Rp1,5jt`
  String toRupiahCompact() {
    if (this >= 1000000000) {
      final value = this / 1000000000;
      final formatted = value == value.truncate()
          ? value.truncate().toString()
          : value.toStringAsFixed(1);
      return 'Rp${formatted}M';
    } else if (this >= 1000000) {
      final value = this / 1000000;
      final formatted = value == value.truncate()
          ? value.truncate().toString()
          : value.toStringAsFixed(1);
      return 'Rp${formatted}jt';
    } else if (this >= 1000) {
      final value = this / 1000;
      final formatted = value == value.truncate()
          ? value.truncate().toString()
          : value.toStringAsFixed(1);
      return 'Rp${formatted}rb';
    }
    return toRupiah();
  }

  /// Apakah nilai ini termasuk kategori "besar" (>= 1 juta)?
  bool get isLargeAmount => this >= 1000000;
}

/// Extension pada [double] untuk format mata uang Rupiah.
extension CurrencyDoubleExtension on double {
  String toRupiah() => toInt().toRupiah();
  String toRupiahCompact() => toInt().toRupiahCompact();
}

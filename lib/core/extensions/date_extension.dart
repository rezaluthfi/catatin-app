/// Extension pada [DateTime] untuk format tanggal dalam Bahasa Indonesia.
///
/// Penggunaan:
/// ```dart
/// final date = DateTime.now();
/// print(date.toDisplayDate()); // → 'Senin, 7 Juli 2026'
/// print(date.toShortDate());   // → '07/07/2026'
/// print(date.toTimeOnly());    // → '21:30'
/// ```
import 'package:intl/intl.dart';

extension DateExtension on DateTime {
  static final _displayFormatter = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
  static final _shortFormatter = DateFormat('dd/MM/yyyy', 'id_ID');
  static final _mediumFormatter = DateFormat('d MMM yyyy', 'id_ID');
  static final _monthYearFormatter = DateFormat('MMMM yyyy', 'id_ID');
  static final _timeFormatter = DateFormat('HH:mm', 'id_ID');
  static final _dbFormatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss");
  static final _dayMonthFormatter = DateFormat('d MMM', 'id_ID');

  /// Format panjang dengan hari: `Senin, 7 Juli 2026`
  String toDisplayDate() => _displayFormatter.format(this);

  /// Format singkat: `07/07/2026`
  String toShortDate() => _shortFormatter.format(this);

  /// Format medium: `7 Jul 2026`
  String toMediumDate() => _mediumFormatter.format(this);

  /// Format bulan-tahun: `Juli 2026`
  String toMonthYear() => _monthYearFormatter.format(this);

  /// Format tanggal-bulan singkat: `7 Jul`
  String toDayMonth() => _dayMonthFormatter.format(this);

  /// Format waktu saja: `21:30`
  String toTimeOnly() => _timeFormatter.format(this);

  /// Format untuk simpan ke database: `2026-07-07T21:30:00`
  String toDbFormat() => _dbFormatter.format(this);

  /// Apakah tanggal ini adalah hari ini?
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Apakah tanggal ini adalah kemarin?
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Apakah tanggal ini dalam minggu yang sama dengan hari ini?
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Kembalikan awal hari (00:00:00) dari tanggal ini.
  DateTime get startOfDay => DateTime(year, month, day);

  /// Kembalikan akhir hari (23:59:59) dari tanggal ini.
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);

  /// Kembalikan awal bulan dari tanggal ini.
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Kembalikan akhir bulan dari tanggal ini.
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59);

  /// Label relatif: `Hari ini`, `Kemarin`, atau format medium.
  String toRelativeLabel() {
    if (isToday) return 'Hari ini';
    if (isYesterday) return 'Kemarin';
    return toMediumDate();
  }
}

/// Extension pada [String] untuk parse dari format database.
extension DateStringExtension on String {
  DateTime? toDateTime() {
    try {
      return DateTime.parse(this);
    } catch (_) {
      return null;
    }
  }
}

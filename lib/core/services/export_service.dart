/// ExportService — Generate laporan PDF dan XLSX.
///
/// Service ini menerima [ExportData] dan menghasilkan [File] yang siap di-share.
/// Tidak bergantung pada Flutter widget tree (murni Dart + paket pdf/excel).
library;

import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'export_data.dart';

class ExportService {
  ExportService._();

  // ──────────────────────────────────────────────────────────
  // Helpers format
  // ──────────────────────────────────────────────────────────

  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _dateFormat = DateFormat('dd/MM/yyyy', 'id_ID');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'id_ID');

  static String _fmt(int amount) => _rupiah.format(amount);
  static String _fmtDate(DateTime dt) => _dateFormat.format(dt);
  static String _fmtDateTime(DateTime dt) => _dateTimeFormat.format(dt);

  static String _periodLabel(DateTime start, DateTime end) =>
      '${_fmtDate(start)} – ${_fmtDate(end)}';

  // ──────────────────────────────────────────────────────────
  // PDF Generation
  // ──────────────────────────────────────────────────────────

  static Future<File> generatePdf(ExportData data) async {
    final pdf = pw.Document();

    // Warna brand
    const brandGreen = PdfColor.fromInt(0xFF198D8D);
    const brandGreenLight = PdfColor.fromInt(0xFFE2F3F3);
    const textSecondary = PdfColor.fromInt(0xFF6B7280);
    const borderColor = PdfColor.fromInt(0xFFE5E7EB);

    // ── Cover / Ringkasan ────────────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _pdfHeader(
          data,
          brandGreen,
          brandGreenLight,
          textSecondary,
        ),
        footer: (ctx) => _pdfFooter(ctx, textSecondary),
        build: (ctx) => [
          // Ringkasan Keuangan
          pw.SizedBox(height: 16),
          _pdfSectionTitle('Ringkasan Keuangan', brandGreen),
          pw.SizedBox(height: 8),
          _pdfSummaryTable(data, brandGreen, brandGreenLight, borderColor),

          pw.SizedBox(height: 24),

          // Transaksi
          _pdfSectionTitle('Riwayat Transaksi', brandGreen),
          pw.SizedBox(height: 8),
          if (data.transactions.isEmpty)
            _pdfEmptyNote('Tidak ada transaksi pada periode ini.', textSecondary)
          else
            _pdfTransactionTable(data, brandGreen, brandGreenLight, borderColor, textSecondary),

          pw.SizedBox(height: 24),

          // Biaya Operasional
          _pdfSectionTitle('Biaya Operasional', brandGreen),
          pw.SizedBox(height: 8),
          if (data.operationalCosts.isEmpty)
            _pdfEmptyNote('Tidak ada biaya operasional pada periode ini.', textSecondary)
          else
            _pdfOperationalTable(data, brandGreen, brandGreenLight, borderColor, textSecondary),

          pw.SizedBox(height: 24),

          // Piutang
          _pdfSectionTitle('Daftar Piutang', brandGreen),
          pw.SizedBox(height: 8),
          if (data.receivables.isEmpty)
            _pdfEmptyNote('Tidak ada data piutang.', textSecondary)
          else
            _pdfReceivableTable(data, brandGreen, brandGreenLight, borderColor, textSecondary),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final filename =
        'CatatIn_Laporan_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ── PDF sub-widgets ──────────────────────────────────────

  static pw.Widget _pdfHeader(
    ExportData data,
    PdfColor brandGreen,
    PdfColor brandGreenLight,
    PdfColor textSecondary,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFE5E7EB), width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CatatIn',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: brandGreen,
                ),
              ),
              pw.Text(
                data.businessName.isNotEmpty ? data.businessName : 'Laporan Keuangan',
                style: pw.TextStyle(fontSize: 11, color: textSecondary),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'LAPORAN KEUANGAN',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Periode: ${_periodLabel(data.startDate, data.endDate)}',
                style: pw.TextStyle(fontSize: 10, color: textSecondary),
              ),
              if (data.ownerName.isNotEmpty)
                pw.Text(
                  'Pemilik: ${data.ownerName}',
                  style: pw.TextStyle(fontSize: 10, color: textSecondary),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfFooter(pw.Context ctx, PdfColor textSecondary) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}  •  Dibuat oleh CatatIn',
        style: pw.TextStyle(fontSize: 9, color: textSecondary),
      ),
    );
  }

  static pw.Widget _pdfSectionTitle(String title, PdfColor brandGreen) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: brandGreen,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _pdfEmptyNote(String text, PdfColor textSecondary) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, color: textSecondary, fontStyle: pw.FontStyle.italic),
      ),
    );
  }

  static pw.Widget _pdfSummaryTable(
    ExportData data,
    PdfColor brandGreen,
    PdfColor brandGreenLight,
    PdfColor borderColor,
  ) {
    final rows = [
      ['Total Pemasukan', _fmt(data.totalRevenue)],
      ['Total Biaya Operasional', _fmt(data.totalOperationalCost)],
      ['Laba Bersih', _fmt(data.netProfit)],
      ['Piutang Belum Lunas', _fmt(data.totalOutstandingReceivables)],
      ['Total Transaksi', '${data.transactions.length} transaksi'],
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      children: rows.asMap().entries.map((entry) {
        final i = entry.key;
        final row = entry.value;
        final isProfitRow = i == 2;
        final isPositiveProfit = data.netProfit > 0;
        
        final rowBgColor = isProfitRow
            ? (isPositiveProfit ? brandGreenLight : PdfColor.fromInt(0xFFFEECEC))
            : (i % 2 == 0 ? PdfColors.white : PdfColor.fromInt(0xFFF9FAFB));
            
        final textCol = isProfitRow
            ? (isPositiveProfit ? brandGreen : PdfColors.red)
            : null;

        return pw.TableRow(
          decoration: pw.BoxDecoration(color: rowBgColor),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: pw.Text(row[0], style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: pw.Text(
                row[1],
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: isProfitRow ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: textCol,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  static pw.Widget _pdfTransactionTable(
    ExportData data,
    PdfColor brandGreen,
    PdfColor brandGreenLight,
    PdfColor borderColor,
    PdfColor textSecondary,
  ) {
    final headers = ['No', 'Tanggal & Waktu', 'Produk', 'Total', 'Pembayaran', 'Catatan'];
    final colWidths = [
      pw.FlexColumnWidth(0.5),
      pw.FlexColumnWidth(2),
      pw.FlexColumnWidth(3),
      pw.FlexColumnWidth(1.8),
      pw.FlexColumnWidth(1.5),
      pw.FlexColumnWidth(2),
    ];

    final headerRow = pw.TableRow(
      decoration: pw.BoxDecoration(color: brandGreen),
      children: headers
          .map((h) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: pw.Text(
                  h,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ))
          .toList(),
    );

    final dataRows = data.transactions.asMap().entries.map((entry) {
      final i = entry.key;
      final tx = entry.value;
      final productList = tx.items.isEmpty
          ? '-'
          : tx.items.map((item) => '${item.productName} (×${item.quantity})').join(', ');
      return pw.TableRow(
        decoration: pw.BoxDecoration(
          color: i % 2 == 0 ? PdfColors.white : PdfColor.fromInt(0xFFF9FAFB),
        ),
        children: [
          _pdfCell('${i + 1}'),
          _pdfCell(_fmtDateTime(tx.createdAt)),
          _pdfCell(productList),
          _pdfCell(_fmt(tx.totalAmount)),
          _pdfCell(tx.paymentMethod.label),
          _pdfCell(tx.notes ?? '-'),
        ],
      );
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      columnWidths: {for (var i = 0; i < colWidths.length; i++) i: colWidths[i]},
      children: [headerRow, ...dataRows],
    );
  }

  static pw.Widget _pdfOperationalTable(
    ExportData data,
    PdfColor brandGreen,
    PdfColor brandGreenLight,
    PdfColor borderColor,
    PdfColor textSecondary,
  ) {
    final headers = ['No', 'Tanggal', 'Deskripsi', 'Jumlah'];

    final headerRow = pw.TableRow(
      decoration: pw.BoxDecoration(color: brandGreen),
      children: headers
          .map((h) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: pw.Text(
                  h,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ))
          .toList(),
    );

    final dataRows = data.operationalCosts.asMap().entries.map((entry) {
      final i = entry.key;
      final cost = entry.value;
      return pw.TableRow(
        decoration: pw.BoxDecoration(
          color: i % 2 == 0 ? PdfColors.white : PdfColor.fromInt(0xFFF9FAFB),
        ),
        children: [
          _pdfCell('${i + 1}'),
          _pdfCell(_fmtDate(cost.date)),
          _pdfCell(cost.description),
          _pdfCell(_fmt(cost.amount)),
        ],
      );
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FlexColumnWidth(2),
      },
      children: [headerRow, ...dataRows],
    );
  }

  static pw.Widget _pdfReceivableTable(
    ExportData data,
    PdfColor brandGreen,
    PdfColor brandGreenLight,
    PdfColor borderColor,
    PdfColor textSecondary,
  ) {
    final headers = ['No', 'Pelanggan', 'Tagihan', 'Dibayar', 'Sisa', 'Status', 'Jatuh Tempo'];

    final headerRow = pw.TableRow(
      decoration: pw.BoxDecoration(color: brandGreen),
      children: headers
          .map((h) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: pw.Text(
                  h,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ))
          .toList(),
    );

    final dataRows = data.receivables.asMap().entries.map((entry) {
      final i = entry.key;
      final r = entry.value;
      return pw.TableRow(
        decoration: pw.BoxDecoration(
          color: i % 2 == 0 ? PdfColors.white : PdfColor.fromInt(0xFFF9FAFB),
        ),
        children: [
          _pdfCell('${i + 1}'),
          _pdfCell(r.customerName),
          _pdfCell(_fmt(r.amount)),
          _pdfCell(_fmt(r.paidAmount)),
          _pdfCell(_fmt(r.remainingAmount)),
          _pdfCell(r.status.label),
          _pdfCell(r.dueDate != null ? _fmtDate(r.dueDate!) : '-'),
        ],
      );
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.4),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.2),
        6: const pw.FlexColumnWidth(1.4),
      },
      children: [headerRow, ...dataRows],
    );
  }

  static pw.Widget _pdfCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  // ──────────────────────────────────────────────────────────
  // XLSX Generation
  // ──────────────────────────────────────────────────────────

  static Future<File> generateXlsx(ExportData data) async {
    final excel = Excel.createExcel();

    // Hapus sheet default "Sheet1" yang dibuat otomatis
    excel.delete('Sheet1');

    _buildSummarySheet(excel, data);
    _buildTransactionSheet(excel, data);
    _buildOperationalSheet(excel, data);
    _buildReceivableSheet(excel, data);

    final dir = await getApplicationDocumentsDirectory();
    final filename =
        'CatatIn_Laporan_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
    final file = File('${dir.path}/$filename');
    final bytes = excel.save();
    if (bytes != null) await file.writeAsBytes(bytes);
    return file;
  }

  // ── XLSX sub-builders ────────────────────────────────────

  static CellStyle _headerStyle() {
    return CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#198D8D'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );
  }

  static CellStyle _boldStyle() {
    return CellStyle(bold: true);
  }

  static CellStyle _moneyStyle() {
    return CellStyle(
      numberFormat: NumFormat.custom(formatCode: '#,##0'),
    );
  }

  static CellStyle _totalStyle() {
    return CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#E2F3F3'),
      numberFormat: NumFormat.custom(formatCode: '#,##0'),
    );
  }

  static void _setHeader(Sheet sheet, int row, List<String> headers) {
    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = _headerStyle();
    }
  }

  static void _buildSummarySheet(Excel excel, ExportData data) {
    final sheet = excel['Ringkasan'];

    // Judul
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('LAPORAN KEUANGAN — ${data.businessName}');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value =
        TextCellValue('Periode: ${_periodLabel(data.startDate, data.endDate)}');
    if (data.ownerName.isNotEmpty) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value =
          TextCellValue('Pemilik: ${data.ownerName}');
    }

    // Header tabel
    _setHeader(sheet, 4, ['Keterangan', 'Nilai (Rp)']);

    final rows = [
      ['Total Pemasukan', data.totalRevenue],
      ['Total Biaya Operasional', data.totalOperationalCost],
      ['Laba Bersih', data.netProfit],
      ['Piutang Belum Lunas', data.totalOutstandingReceivables],
      ['Jumlah Transaksi', data.transactions.length],
    ];

    for (var i = 0; i < rows.length; i++) {
      final rowIdx = 5 + i;
      final isProfit = i == 2;
      final labelCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx));
      labelCell.value = TextCellValue(rows[i][0] as String);
      if (isProfit) labelCell.cellStyle = _boldStyle();

      final valCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx));
      if (rows[i][1] is int) {
        valCell.value = IntCellValue(rows[i][1] as int);
        valCell.cellStyle = isProfit ? _totalStyle() : _moneyStyle();
      } else {
        valCell.value = TextCellValue('${rows[i][1]}');
      }
    }

    // Set column widths
    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(1, 20);
  }

  static void _buildTransactionSheet(Excel excel, ExportData data) {
    final sheet = excel['Transaksi'];

    _setHeader(sheet, 0, [
      'No', 'Tanggal', 'Waktu', 'Produk', 'Qty Total',
      'Total (Rp)', 'Metode Bayar', 'Catatan',
    ]);

    for (var i = 0; i < data.transactions.length; i++) {
      final tx = data.transactions[i];
      final rowIdx = i + 1;
      final productList = tx.items.isEmpty
          ? '-'
          : tx.items.map((item) => '${item.productName} ×${item.quantity}').join(', ');
      final totalQty = tx.items.fold(0, (sum, item) => sum + item.quantity);

      final row = [
        IntCellValue(i + 1),
        TextCellValue(_fmtDate(tx.createdAt)),
        TextCellValue(DateFormat('HH:mm').format(tx.createdAt)),
        TextCellValue(productList),
        IntCellValue(totalQty),
        IntCellValue(tx.totalAmount),
        TextCellValue(tx.paymentMethod.label),
        TextCellValue(tx.notes ?? '-'),
      ];

      for (var col = 0; col < row.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx));
        cell.value = row[col];
        if (col == 5) cell.cellStyle = _moneyStyle();
      }
    }

    // Baris total
    if (data.transactions.isNotEmpty) {
      final totalRow = data.transactions.length + 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRow)).value =
          TextCellValue('TOTAL');
      final totalCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRow));
      totalCell.value = IntCellValue(data.totalRevenue);
      totalCell.cellStyle = _totalStyle();
    }

    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 14);
    sheet.setColumnWidth(2, 10);
    sheet.setColumnWidth(3, 40);
    sheet.setColumnWidth(4, 12);
    sheet.setColumnWidth(5, 18);
    sheet.setColumnWidth(6, 15);
    sheet.setColumnWidth(7, 25);
  }

  static void _buildOperationalSheet(Excel excel, ExportData data) {
    final sheet = excel['Biaya Operasional'];

    _setHeader(sheet, 0, ['No', 'Tanggal', 'Deskripsi', 'Jumlah (Rp)']);

    for (var i = 0; i < data.operationalCosts.length; i++) {
      final cost = data.operationalCosts[i];
      final rowIdx = i + 1;
      final row = [
        IntCellValue(i + 1),
        TextCellValue(_fmtDate(cost.date)),
        TextCellValue(cost.description),
        IntCellValue(cost.amount),
      ];
      for (var col = 0; col < row.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx));
        cell.value = row[col];
        if (col == 3) cell.cellStyle = _moneyStyle();
      }
    }

    if (data.operationalCosts.isNotEmpty) {
      final totalRow = data.operationalCosts.length + 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: totalRow)).value =
          TextCellValue('TOTAL');
      final totalCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: totalRow));
      totalCell.value = IntCellValue(data.totalOperationalCost);
      totalCell.cellStyle = _totalStyle();
    }

    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 14);
    sheet.setColumnWidth(2, 35);
    sheet.setColumnWidth(3, 18);
  }

  static void _buildReceivableSheet(Excel excel, ExportData data) {
    final sheet = excel['Piutang'];

    _setHeader(sheet, 0, [
      'No', 'Nama Pelanggan', 'Total Tagihan (Rp)', 'Sudah Dibayar (Rp)',
      'Sisa Utang (Rp)', 'Status', 'Jatuh Tempo', 'Catatan',
    ]);

    for (var i = 0; i < data.receivables.length; i++) {
      final r = data.receivables[i];
      final rowIdx = i + 1;
      final row = [
        IntCellValue(i + 1),
        TextCellValue(r.customerName),
        IntCellValue(r.amount),
        IntCellValue(r.paidAmount),
        IntCellValue(r.remainingAmount),
        TextCellValue(r.status.label),
        TextCellValue(r.dueDate != null ? _fmtDate(r.dueDate!) : '-'),
        TextCellValue(r.notes ?? '-'),
      ];
      for (var col = 0; col < row.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx));
        cell.value = row[col];
        if (col == 2 || col == 3 || col == 4) cell.cellStyle = _moneyStyle();
      }
    }

    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 25);
    sheet.setColumnWidth(2, 20);
    sheet.setColumnWidth(3, 20);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 15);
    sheet.setColumnWidth(6, 14);
    sheet.setColumnWidth(7, 30);
  }
}

/// Bottom sheet untuk konfigurasi dan eksekusi ekspor laporan.
///
/// User memilih rentang tanggal dan format (PDF / XLSX),
/// lalu mengetuk "Export & Bagikan" untuk menjalankan proses.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../providers/export_provider.dart';
import '../providers/settings_provider.dart';

class ExportSheet extends ConsumerStatefulWidget {
  const ExportSheet({super.key});

  @override
  ConsumerState<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<ExportSheet> {
  // Default: bulan berjalan
  late DateTime _startDate;
  late DateTime _endDate;
  ExportFormat _format = ExportFormat.pdf;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      helpText: 'Pilih Periode Laporan',
      confirmText: 'Pilih',
      cancelText: 'Batal',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.expense,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _exportAndShare() async {
    final notifier = ref.read(exportProvider.notifier);
    final file = await notifier.generateReport(
      startDate: _startDate,
      endDate: _endDate,
      format: _format,
    );

    if (file == null) {
      _showErrorSnackBar('Gagal membuat laporan.');
      return;
    }

    // Share the file
    final settingsState = await ref.read(settingsProvider.future);
    final result = await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Laporan Keuangan ${settingsState.businessName}',
      text:
          'Laporan keuangan CatatIn — '
          '${_formatDate(_startDate)} s/d '
          '${_formatDate(_endDate)}',
    );

    if (!mounted) return;
    
    if (result.status == ShareResultStatus.success || 
        result.status == ShareResultStatus.unavailable) {
      Navigator.pop(context);
      _showSuccessSnackBar('Laporan berhasil dibagikan!');
    }
  }

  Future<void> _exportAndSave() async {
    final notifier = ref.read(exportProvider.notifier);
    final file = await notifier.generateReport(
      startDate: _startDate,
      endDate: _endDate,
      format: _format,
    );

    if (file == null) {
      _showErrorSnackBar('Gagal membuat laporan.');
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      final ext = _format == ExportFormat.pdf ? '.pdf' : '.xlsx';

      final startFmt = _formatDate(_startDate).replaceAll('/', '-');
      final endFmt = _formatDate(_endDate).replaceAll('/', '-');
      final fileName = 'CatatIn_Laporan_${startFmt}_s-d_$endFmt$ext';

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Laporan',
        fileName: fileName,
        bytes: bytes,
      );

      if (path != null && mounted) {
        Navigator.pop(context);
        _showSuccessSnackBar('Laporan berhasil disimpan di perangkat!');
      }
    } catch (e) {
      _showErrorSnackBar('Gagal menyimpan laporan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportProvider);
    final isLoading = exportState is AsyncLoading;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        16 +
            MediaQuery.of(context).padding.bottom +
            MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Export Laporan', style: AppTextStyles.headingSmall),
                    Text(
                      'Pilih periode dan format file',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Periode
            Text('Periode Laporan', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            InkWell(
              onTap: isLoading ? null : _pickDateRange,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.background,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.date_range_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_formatDate(_startDate)}  →  ${_formatDate(_endDate)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Format pilihan
            Text('Format File', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _FormatCard(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'PDF',
                    description: 'Siap cetak & share',
                    color: const Color(0xFFE53E3E),
                    isSelected: _format == ExportFormat.pdf,
                    onTap: isLoading
                        ? null
                        : () => setState(() => _format = ExportFormat.pdf),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FormatCard(
                    icon: Icons.table_chart_rounded,
                    label: 'XLSX',
                    description: 'Untuk analisis Excel',
                    color: const Color(0xFF1A7A4A),
                    isSelected: _format == ExportFormat.xlsx,
                    onTap: isLoading
                        ? null
                        : () => setState(() => _format = ExportFormat.xlsx),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Tombol export / save / share
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _exportAndSave,
                  icon: const Icon(Icons.save_alt_rounded),
                  label: const Text('Simpan di Perangkat'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _exportAndShare,
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Bagikan Laporan'),
                ),
              ),
              const SizedBox(
                height: 48,
              ), // Large bottom spacer to prevent overlapping with FAB
            ],
          ],
        ),
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  const _FormatCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.isSelected,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textSecondary,
              size: 26,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                color: isSelected ? color : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(description, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

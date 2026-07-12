/// Settings Screen — Profil Usaha, Keamanan, Backup & Restore, Tentang.
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil & Pengaturan'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: stateAsync.when(
        data: (state) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // -- Avatar & Nama Usaha -----------------------------
            _buildProfileHeader(context, ref, state),

            const SizedBox(height: 8),

            // -- Seksi Profil Usaha ------------------------------
            _buildSectionHeader('Profil Usaha'),
            _buildTile(
              icon: Icons.store_rounded,
              iconColor: AppColors.primary,
              title: 'Nama Usaha',
              subtitle: state.businessName.isEmpty
                  ? 'Belum diatur'
                  : state.businessName,
              onTap: () => _showEditDialog(
                context,
                ref,
                title: 'Nama Usaha',
                currentValue: state.businessName,
                hint: 'Masukkan nama usaha Anda',
                onSave: (val) =>
                    ref.read(settingsProvider.notifier).updateBusinessName(val),
              ),
            ),
            _buildTile(
              icon: Icons.person_rounded,
              iconColor: AppColors.info,
              title: 'Nama Pemilik',
              subtitle: state.ownerName.isEmpty
                  ? 'Belum diatur'
                  : state.ownerName,
              onTap: () => _showEditDialog(
                context,
                ref,
                title: 'Nama Pemilik',
                currentValue: state.ownerName,
                hint: 'Masukkan nama pemilik usaha',
                onSave: (val) =>
                    ref.read(settingsProvider.notifier).updateOwnerName(val),
              ),
            ),
            _buildTile(
              icon: Icons.percent_rounded,
              iconColor: AppColors.primary,
              title: 'Margin Keuntungan Default',
              subtitle: '${state.defaultMargin}%',
              onTap: () => _showEditDialog(
                context,
                ref,
                title: 'Margin Keuntungan Default (%)',
                currentValue: state.defaultMargin.toString(),
                hint: 'Masukkan persentase margin (mis: 30)',
                keyboardType: TextInputType.number,
                onSave: (val) async {
                  final margin = int.tryParse(val) ?? 30;
                  await ref
                      .read(settingsProvider.notifier)
                      .updateDefaultMargin(margin);
                },
              ),
            ),

            const SizedBox(height: 8),

            // -- Seksi Keamanan ----------------------------------
            _buildSectionHeader('Keamanan'),
            _buildTile(
              icon: Icons.lock_outline_rounded,
              iconColor: AppColors.warning,
              title: 'Ubah PIN',
              subtitle: 'Ganti PIN untuk membuka aplikasi',
              onTap: () => context.push(AppRoutes.changePin),
            ),

            const SizedBox(height: 8),

            // -- Seksi Data --------------------------------------
            _buildSectionHeader('Data & Backup'),
            _buildTile(
              icon: Icons.upload_file_rounded,
              iconColor: AppColors.income,
              title: 'Backup Data',
              subtitle: 'Ekspor semua data ke file JSON',
              isLoading: state.isExporting,
              onTap: () => _showBackupOptions(context, ref),
            ),
            _buildTile(
              icon: Icons.download_rounded,
              iconColor: AppColors.secondary,
              title: 'Pulihkan Data',
              subtitle: 'Impor data dari file backup',
              isLoading: state.isImporting,
              onTap: () => _doImport(context, ref),
            ),

            const SizedBox(height: 8),

            // -- Seksi Tentang -----------------------------------
            _buildSectionHeader('Tentang Aplikasi'),
            _buildTile(
              icon: Icons.info_outline_rounded,
              iconColor: AppColors.textSecondary,
              title: 'Versi Aplikasi',
              subtitle: AppConstants.appVersion,
              onTap: null,
            ),
            _buildTile(
              icon: Icons.favorite_outline_rounded,
              iconColor: AppColors.expense,
              title: 'Tentang Catatin',
              subtitle: AppConstants.appDeveloper,
              onTap: null,
            ),
            const SizedBox(height: 32),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
      ),
    );
  }

  // -------------------------------------------------------------
  // Widgets
  // -------------------------------------------------------------

  Widget _buildProfileHeader(BuildContext context, WidgetRef ref, settings) {
    final initials =
        (settings.businessName.isNotEmpty ? settings.businessName : 'C')
            .substring(0, 1)
            .toUpperCase();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              initials,
              style: AppTextStyles.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.businessName.isEmpty
                      ? 'Nama Usaha'
                      : settings.businessName,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (settings.ownerName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    settings.ownerName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : (onTap != null
                  ? const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    )
                  : null),
        onTap: isLoading ? null : onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // -------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String currentValue,
    required String hint,
    required Future<void> Function(String) onSave,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await onSave(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title berhasil diperbarui'),
            backgroundColor: AppColors.income,
          ),
        );
      }
    }
  }

  Future<void> _doExport(BuildContext context, WidgetRef ref) async {
    final path = await ref.read(settingsProvider.notifier).exportData();
    if (!context.mounted) return;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengekspor data. Coba lagi.'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  Future<void> _doImport(BuildContext context, WidgetRef ref) async {
    // Konfirmasi sebelum import
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pulihkan Data?'),
        content: const Text(
          'Semua data yang ada saat ini akan diganti dengan data dari file backup. '
          'Tindakan ini tidak dapat dibatalkan.\n\nLanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Pulihkan'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Buka file picker
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return;
    if (!context.mounted) return;

    final file = File(result.files.single.path!);
    final content = await file.readAsString();

    final success = await ref
        .read(settingsProvider.notifier)
        .importData(content);

    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Data berhasil dipulihkan! Restart aplikasi untuk melihat perubahan.',
          ),
          backgroundColor: AppColors.income,
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      final error = ref.read(settingsProvider).valueOrNull?.importError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Gagal memulihkan data. Pastikan file valid.'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  void _showBackupOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Pilih Metode Backup', style: AppTextStyles.headlineSmall),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.income.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.save_alt_rounded, color: AppColors.income),
                ),
                title: Text('Simpan di Perangkat (Lokal)', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                subtitle: const Text('Simpan file backup secara lokal ke memori perangkat'),
                onTap: () async {
                  Navigator.pop(context);
                  _doSaveLocal(context, ref);
                },
              ),
              const Divider(height: 16),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.share_rounded, color: AppColors.primary),
                ),
                title: Text('Bagikan Berkas (Share)', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                subtitle: const Text('Kirim file backup melalui WhatsApp, Email, Drive, dll.'),
                onTap: () {
                  Navigator.pop(context);
                  _doExport(context, ref);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _doSaveLocal(BuildContext context, WidgetRef ref) async {
    try {
      final jsonString = await ref.read(settingsProvider.notifier).getBackupJson();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);
      final fileName =
          '${AppConstants.exportFileName}_$timestamp${AppConstants.exportFileExtension}';

      final bytes = utf8.encode(jsonString);
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Backup Data',
        fileName: fileName,
        bytes: bytes,
      );

      if (path != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup berhasil disimpan di perangkat!'),
            backgroundColor: AppColors.income,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan backup: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }
}

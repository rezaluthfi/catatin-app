/// MainShell — Scaffold utama dengan BottomNavigationBar (Mobile) dan Sidebar (Desktop).
///
/// Mengimplementasikan pola navigasi yang disesuaikan per platform:
/// - Desktop (width >= 768): Left Navigation Sidebar dengan branding, quick POS button, dan nav tiles.
/// - Mobile  (width < 768): BottomNavigationBar dengan FAB POS di tengah.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../../core/widgets/app_footer.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  /// Daftar route yang tersedia di nav (sesuai urutan index).
  /// Index: 0=Dashboard, 1=Inventaris, 2=Rekap, 3=Profil
  static const _tabs = [
    AppRoutes.dashboard, // index 0
    AppRoutes.inventory, // index 1
    AppRoutes.recap, // index 2
    AppRoutes.settings, // index 3
  ];

  /// Kembalikan index tab aktif berdasarkan route saat ini.
  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final currentIndex = _currentIndex(context);

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // --- DESKTOP NAVIGATION SIDEBAR ---
            Container(
              width: 250,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  right: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Column(
                children: [
                  // App Branding Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/logo_bg_primary.jpeg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CatatIn',
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              'Kasir & Keuangan',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: AppColors.border),

                  // Quick Action POS Button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push(AppRoutes.pos),
                        icon: const Icon(Icons.add_shopping_cart, size: 20),
                        label: const Text(
                          'Catat Transaksi',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Sidebar Menu Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _SidebarTile(
                          icon: Icons.dashboard_outlined,
                          activeIcon: Icons.dashboard,
                          label: 'Dashboard',
                          isActive: currentIndex == 0,
                          onTap: () => context.go(_tabs[0]),
                        ),
                        const SizedBox(height: 4),
                        _SidebarTile(
                          icon: Icons.inventory_2_outlined,
                          activeIcon: Icons.inventory_2,
                          label: 'Inventaris Produk',
                          isActive: currentIndex == 1,
                          onTap: () => context.go(_tabs[1]),
                        ),
                        const SizedBox(height: 4),
                        _SidebarTile(
                          icon: Icons.insert_chart_outlined,
                          activeIcon: Icons.insert_chart,
                          label: 'Rekapitulasi',
                          isActive: currentIndex == 2,
                          onTap: () => context.go(_tabs[2]),
                        ),
                        const SizedBox(height: 4),
                        _SidebarTile(
                          icon: Icons.person_outline,
                          activeIcon: Icons.person,
                          label: 'Profil & Pengaturan',
                          isActive: currentIndex == 3,
                          onTap: () => context.go(_tabs[3]),
                        ),
                      ],
                    ),
                  ),

                  // Footer Copyright
                  const AppFooter(),
                ],
              ),
            ),

            // --- MAIN CONTENT ---
            Expanded(child: child),
          ],
        ),
      );
    }

    // --- MOBILE NAVIGATION BAR ---
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: child,
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => context.push(AppRoutes.pos),
        tooltip: 'Catat Transaksi',
        child: const Icon(Icons.add_shopping_cart, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: 'Dashboard',
                    isActive: currentIndex == 0,
                    onTap: () => context.go(_tabs[0]),
                  ),
                  _NavItem(
                    icon: Icons.inventory_2_outlined,
                    activeIcon: Icons.inventory_2,
                    label: 'Inventaris',
                    isActive: currentIndex == 1,
                    onTap: () => context.go(_tabs[1]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 64),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(
                    icon: Icons.insert_chart_outlined,
                    activeIcon: Icons.insert_chart,
                    label: 'Rekap',
                    isActive: currentIndex == 2,
                    onTap: () => context.go(_tabs[2]),
                  ),
                  _NavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profil',
                    isActive: currentIndex == 3,
                    onTap: () => context.go(_tabs[3]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item menu untuk Desktop Navigation Sidebar.
class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeBg = AppColors.primary.withValues(alpha: 0.12);
    final activeColor = AppColors.primary;
    final inactiveColor = AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? activeColor : inactiveColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isActive ? activeColor : AppColors.textPrimary,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget untuk setiap item di bottom navigation bar (Mobile).
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

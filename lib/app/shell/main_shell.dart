/// MainShell — Scaffold utama dengan BottomNavigationBar dan FAB POS.
///
/// Mengimplementasikan pola navigasi yang sudah disepakati di PRD:
/// [Dashboard] [Inventarisasi]  (+POS)  [Rekapitulasi] [Profil]
///
/// FAB diposisikan di tengah (centerDocked) sebagai akses cepat ke POS.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  /// Daftar route yang tersedia di bottom nav (sesuai urutan index).
  /// Index: 0=Dashboard, 1=Inventaris, 2=Rekap, 3=Profil
  static const _tabs = [
    AppRoutes.dashboard,   // index 0
    AppRoutes.inventory,   // index 1
    AppRoutes.recap,       // index 2
    AppRoutes.settings,    // index 3
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
    final currentIndex = _currentIndex(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: child,
      // FAB di tengah untuk akses cepat POS
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-pos',
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
                  // Tab 0: Dashboard
                  _NavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: 'Dashboard',
                    isActive: currentIndex == 0,
                    onTap: () => context.go(_tabs[0]),
                  ),
                  // Tab 1: Inventaris
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
            // Ruang kosong untuk FAB agar benar-benar di tengah
            const SizedBox(width: 64),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Tab 2: Rekap
                  _NavItem(
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart,
                    label: 'Rekap',
                    isActive: currentIndex == 2,
                    onTap: () => context.go(_tabs[2]),
                  ),
                  // Tab 3: Profil
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

/// Widget untuk setiap item di bottom navigation bar.
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

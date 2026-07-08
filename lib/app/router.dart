/// Router terpusat menggunakan go_router.
///
/// Semua route aplikasi didefinisikan di sini agar navigasi mudah
/// dilacak dan dimodifikasi dari satu tempat.
import 'package:go_router/go_router.dart';

import '../features/auth/screens/pin_lock_screen.dart';
import '../features/auth/screens/pin_setup_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/inventory/screens/inventory_list_screen.dart';
import '../features/inventory/screens/product_form_screen.dart';
import '../features/pos/screens/pos_screen.dart';
import '../features/receivables/screens/receivables_list_screen.dart';
import '../features/receivables/screens/receivable_form_screen.dart';
import '../features/recap/screens/recap_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import 'shell/main_shell.dart';

/// Nama path route yang digunakan di seluruh aplikasi.
/// Gunakan konstanta ini (bukan string literal) saat navigasi.
class AppRoutes {
  AppRoutes._(); // Prevent instantiation

  static const String pinSetup = '/pin-setup';
  static const String pinLock = '/pin-lock';
  static const String dashboard = '/dashboard';
  static const String inventory = '/inventory';
  static const String recap = '/recap';
  static const String settings = '/settings';
  static const String productAdd = '/product/add';
  static const String productEdit = '/product/:id/edit';
  static const String pos = '/pos';
  static const String receivables = '/receivables';
  static const String receivableAdd = '/receivable/add';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.pinLock,
  debugLogDiagnostics: true,
  routes: [
    // ── Auth ──────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.pinSetup,
      name: 'pin-setup',
      builder: (context, state) => const PinSetupScreen(),
    ),
    GoRoute(
      path: AppRoutes.pinLock,
      name: 'pin-lock',
      builder: (context, state) => const PinLockScreen(),
    ),

    // ── Main Shell (BottomAppBar) ─────────────────────────────
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          name: 'dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.inventory,
          name: 'inventory',
          builder: (context, state) => const InventoryListScreen(),
        ),
        GoRoute(
          path: AppRoutes.recap,
          name: 'recap',
          builder: (context, state) => const RecapScreen(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),

    // ── Inventory Detail (di luar shell) ─────────────────────
    GoRoute(
      path: AppRoutes.productAdd,
      name: 'product-add',
      builder: (context, state) => const ProductFormScreen(),
    ),
    GoRoute(
      path: AppRoutes.productEdit,
      name: 'product-edit',
      builder: (context, state) {
        final productId = state.pathParameters['id']!;
        return ProductFormScreen(productId: productId);
      },
    ),

    // ── POS ──────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.pos,
      name: 'pos',
      builder: (context, state) => const PosScreen(),
    ),

    // ── Piutang ──────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.receivables,
      name: 'receivables',
      builder: (context, state) => const ReceivablesListScreen(),
    ),
    GoRoute(
      path: AppRoutes.receivableAdd,
      name: 'receivable-add',
      builder: (context, state) => const ReceivableFormScreen(),
    ),
  ],
);

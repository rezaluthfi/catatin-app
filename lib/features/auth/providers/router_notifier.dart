// RouterNotifier — jembatan antara Riverpod auth state dan GoRouter.
//
// Mengimplementasikan [Listenable] agar GoRouter bisa memanggil redirect
// setiap kali auth state berubah (login, logout, setup selesai).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import 'auth_provider.dart';
import 'auth_state.dart';

/// Provider untuk RouterNotifier.
/// Di-watch oleh [routerProvider] agar GoRouter mendapat notifikasi perubahan.
final routerNotifierProvider =
    AsyncNotifierProvider<RouterNotifier, void>(RouterNotifier.new);

/// Menjembatani perubahan [AuthState] ke GoRouter melalui [Listenable].
///
/// Setiap kali [authProvider] berubah, notifier ini memanggil semua listener
/// yang didaftarkan GoRouter, sehingga GoRouter menjalankan ulang [redirect].
class RouterNotifier extends AsyncNotifier<void> implements Listenable {
  final ObserverList<VoidCallback> _listeners = ObserverList<VoidCallback>();

  @override
  Future<void> build() async {
    // Pantau perubahan auth state dan teruskan ke GoRouter
    ref.listen<AsyncValue<AuthState>>(
      authProvider,
      (_, __) => _notifyListeners(),
    );
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  // ─────────────────────────────────────────────────────────────
  // Redirect Logic
  // ─────────────────────────────────────────────────────────────

  /// Dipanggil GoRouter setiap kali state berubah atau navigasi terjadi.
  /// Mengembalikan path tujuan redirect, atau null jika tidak perlu redirect.
  String? redirect(BuildContext context, GoRouterState routerState) {
    final authValue = ref.read(authProvider);

    // Masih loading → jangan redirect
    if (authValue.isLoading || authValue.hasError) return null;

    final auth = authValue.valueOrNull;
    if (auth == null) return null;

    final currentPath = routerState.uri.toString();
    final isOnSetup = currentPath.startsWith(AppRoutes.pinSetup);
    final isOnLock = currentPath.startsWith(AppRoutes.pinLock);

    switch (auth.status) {
      case AuthStatus.loading:
        return null;

      // PIN belum dibuat → wajib ke setup
      case AuthStatus.firstRun:
        return isOnSetup ? null : AppRoutes.pinSetup;

      // PIN ada tapi belum dimasukkan → wajib ke lock
      case AuthStatus.locked:
        return isOnLock ? null : AppRoutes.pinLock;

      // Sudah authenticated → jika masih di halaman auth, kirim ke dashboard
      case AuthStatus.authenticated:
        if (isOnSetup || isOnLock) return AppRoutes.dashboard;
        return null;
    }
  }
}

// Basic smoke test untuk aplikasi Catatin.
// Test lebih lengkap akan ditambahkan seiring pengembangan fitur.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catatin/app/app.dart';

void main() {
  testWidgets('Catatin app smoke test — menampilkan PIN lock screen',
      (WidgetTester tester) async {
    // Build app dengan ProviderScope
    await tester.pumpWidget(
      const ProviderScope(child: CatatinApp()),
    );

    // Verifikasi bahwa PIN lock screen ditampilkan
    await tester.pumpAndSettle();
    expect(find.text('Catatin'), findsOneWidget);
  });
}

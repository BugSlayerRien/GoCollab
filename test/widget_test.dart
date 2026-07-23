// Basic smoke tests for GoCollab's foundational, network-independent
// widgets. Full app boot (main.dart) requires a live Supabase session and
// is exercised via manual/integration testing rather than here, since
// Supabase.initialize() performs real network I/O unsuitable for a fast
// widget test suite.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gocollab/core/theme/app_theme.dart';
import 'package:gocollab/core/utils/validators.dart';
import 'package:gocollab/features/splash/presentation/screens/splash_screen.dart';

void main() {
  group('Validators', () {
    test('rejects invalid emails', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('member@gdgoc.ph'), isNull);
    });

    test('enforces password strength rules', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('nouppercase123'), isNotNull);
      expect(Validators.password('NoNumberHere'), isNotNull);
      expect(Validators.password('ValidPass123'), isNull);
    });
  });

  testWidgets('SplashScreen renders the GoCollab brand mark', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const SplashScreen()));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('GoCollab'), findsOneWidget);
    expect(find.text('GDGoC Philippines'), findsOneWidget);
  });
}

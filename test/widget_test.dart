import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/services/preferences_provider.dart';
import 'package:focus/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('FocusApp shows the preview screen', (tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const FocusApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('FOCUS'), findsWidgets);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Arabic locale uses RTL', (tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ar'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const FocusApp(),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    expect(Directionality.of(context), TextDirection.rtl);
  });
}

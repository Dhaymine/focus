import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/services/preferences_provider.dart';
import 'package:focus/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(WidgetTester tester, String locale) async {
  SharedPreferences.setMockInitialValues({'app_locale': locale});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const FocusApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Home dashboard is shown first', (tester) async {
    await _pumpApp(tester, 'en');
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Start Pomodoro'), findsOneWidget);
  });

  testWidgets('Navigating to Tasks shows its screen', (tester) async {
    await _pumpApp(tester, 'en');
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    expect(find.text('Coming in phase 5'), findsOneWidget);
  });

  testWidgets('Arabic locale uses RTL', (tester) async {
    await _pumpApp(tester, 'ar');
    final context = tester.element(find.byType(Scaffold).first);
    expect(Directionality.of(context), TextDirection.rtl);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/database/app_database.dart';
import 'package:focus/core/services/preferences_provider.dart';
import 'package:focus/features/pomodoro/data/history_repository.dart';
import 'package:focus/features/tasks/data/task_providers.dart';
import 'package:focus/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(WidgetTester tester, String locale) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({'app_locale': locale});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Data streams are faked so tests never open a real database.
        tasksProvider.overrideWith((ref) => Stream.value(const <TaskRow>[])),
        subtasksProvider
            .overrideWith((ref) => Stream.value(const <SubtaskRow>[])),
        categoriesProvider
            .overrideWith((ref) => Stream.value(const <CategoryRow>[])),
        todayStudyMsProvider.overrideWith((ref) => Stream.value(0)),
      ],
      child: const FocusApp(),
    ),
  );
  // The timer clock ticks forever, so pumpAndSettle would never settle.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  final error = tester.takeException();
  if (error != null) {
    fail('Exception while building the app: $error');
  }
}

void main() {
  testWidgets('Home dashboard is shown first', (tester) async {
    await _pumpApp(tester, 'en');
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Start Pomodoro'), findsWidgets);
  });

  testWidgets('Navigating to Tasks shows the empty state', (tester) async {
    await _pumpApp(tester, 'en');
    await tester.tap(find.text('Tasks'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('No tasks yet'), findsOneWidget);
  });

  testWidgets('Arabic locale uses RTL', (tester) async {
    await _pumpApp(tester, 'ar');
    final context = tester.element(find.byType(Scaffold).first);
    expect(Directionality.of(context), TextDirection.rtl);
  });
}

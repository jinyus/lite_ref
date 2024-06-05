// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_example/deps.dart';
import 'package:flutter_example/main.dart';
import 'package:flutter_example/settings/controller.dart';
import 'package:flutter_example/settings/service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lite_ref/lite_ref.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsService extends Mock implements SettingsService {}

class MockSettingsController extends Mock implements SettingsController {}

void main() {
  final mockSettingsService = MockSettingsService();
  final mockSettingsController = MockSettingsController();

  testWidgets('Controller test', (WidgetTester tester) async {
    when(mockSettingsController.loadSettings).thenAnswer((_) async {});

    when(() => mockSettingsController.themeMode).thenReturn(ThemeMode.dark);

    when(() => mockSettingsController.updateThemeMode(null)).thenAnswer(
      (_) async {},
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      LiteRefScope(
        overrides: {
          settingsServiceRef.overrideWith((_) {
            return mockSettingsService;
          }),
          settingsControllerRef.overrideWith((_) async {
            return mockSettingsController;
          }),
        },
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that our counter starts at 0.
    expect(find.byType(HomePage), findsOneWidget);

    final btn = find.byKey(const Key('settings'));

    expect(btn, findsOneWidget);

    await tester.tap(btn);

    await tester.pumpAndSettle();

    expect(find.text('Dark Theme'), findsOneWidget);

    when(() => mockSettingsController.themeMode).thenReturn(ThemeMode.light);

    await tester.pumpAndSettle();

    // go back
    await tester.pageBack();

    await tester.pumpAndSettle();

    await tester.tap(btn);

    await tester.pumpAndSettle();

    expect(find.text('Light Theme'), findsOneWidget);
  });
}

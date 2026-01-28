// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sltb_board_of_survey/main.dart';

void main() {
  testWidgets('Login screen renders', (WidgetTester tester) async {
    // Pump the app with ProviderScope (required by Riverpod).
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Let initial animations settle a bit.
    await tester.pump(const Duration(milliseconds: 50));

    // Verify expected login UI elements.
    expect(find.text('SLTB Board of Survey'), findsOneWidget);
    expect(find.text('Equipment Survey System'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });
}

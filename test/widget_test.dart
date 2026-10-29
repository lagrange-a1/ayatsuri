import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ayatsuri/main.dart';

void main() async {
  // `main()` is not called by the widget test, so dotenv must be loaded
  // inside the test body (the binding already exists there).
  testWidgets('App has a map page and a bottom navigation bar',
      (WidgetTester tester) async {
    await dotenv.load();
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // The info page is the first tab, requesting controller state in the
    // background (there may or may not be a live controller in the test env).
    expect(find.text('No data yet'), findsOneWidget);

    // The bottom navigation bar exists and has two items.
    expect(find.byIcon(Icons.info), findsOneWidget);
    expect(find.byIcon(Icons.public), findsOneWidget);

    // Tap the map tab.
    await tester.tap(find.byIcon(Icons.public));
    await tester.pumpAndSettle();

    // The map page exists and can search for candidate nodes.
    expect(find.text('Select a node · World Map'), findsOneWidget);
    expect(find.text('Tap a country on the map.'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ayatsuri/main.dart';

void main() async {
  // `main()` is not called by the widget test, so dotenv must be loaded
  // inside the test body (the binding already exists there).
  testWidgets('App has a map page and a bottom navigation bar', (
    WidgetTester tester,
  ) async {
    await dotenv.load();
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // The map page is now the home tab; it fetches proxies and groups on
    // startup (the requests are fire-and-forget, so the first frame is still
    // empty).
    expect(find.text('Select a node · World Map'), findsOneWidget);
    expect(find.text('Tap a country on the map.'), findsOneWidget);
    expect(find.byIcon(Icons.public), findsOneWidget);
    expect(find.byIcon(Icons.info), findsOneWidget);

    // The info tab also fetches on startup; the error state is environment
    // dependent (9091 is auth-gated here), so any rendered article state is
    // accepted.
    await tester.tap(find.byIcon(Icons.info));
    // Pump and settle clears the timers created by the startup fetches,
    // otherwise the framework complains about pending timers after the widget
    // tree is disposed.
    await tester.pumpAndSettle();
    expect(find.text('ayatsuri · Mihomo Info'), findsOneWidget);
  });
}

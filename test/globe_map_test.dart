import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ayatsuri/main.dart';

void main() {
  testWidgets('Globe shows loading indicator on first frame', (
    WidgetTester tester,
  ) async {
    dotenv.loadFromString(envString: 'host=localhost\nport=9091\nsecret=***\n');
    await tester.pumpWidget(MyApp());
    // First frame: selection/geo data not yet loaded, so the loading
    // state must be distinguishable from the empty state.
    expect(find.byKey(const ValueKey('globe-loading')), findsOneWidget);
    expect(find.byKey(const ValueKey('globe-empty')), findsNothing);
    // Globe placeholder and hint remain visible behind the indicator.
    expect(find.text('Globe (3D unavailable in tests)'), findsOneWidget);
    expect(find.text('Tap a Country/Region'), findsOneWidget);
    // Flush pending timers (load retries) before disposal.
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();
  });
}

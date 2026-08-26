import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/app.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: App()),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
    // Advance timers so splash screen delay and auth check complete
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump();
  });
}

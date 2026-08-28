import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/shared/widgets/empty_state.dart';
import 'package:iptv/shared/widgets/error_view.dart';

void main() {
  testWidgets('empty state supports contextual slots', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EmptyState(
          title: 'Nothing saved',
          eyebrow: 'FAVORITES',
          illustration: SizedBox(key: ValueKey('empty-illustration')),
          secondaryAction: Text('Browse channels'),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('empty-illustration')), findsOneWidget);
    expect(find.text('FAVORITES'), findsOneWidget);
    expect(find.text('Browse channels'), findsOneWidget);
  });

  testWidgets('error view supports contextual slots', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ErrorView(
          message: 'Connection failed',
          eyebrow: 'SERVER',
          illustration: SizedBox(key: ValueKey('error-illustration')),
          secondaryAction: Text('Change provider'),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('error-illustration')), findsOneWidget);
    expect(find.text('SERVER'), findsOneWidget);
    expect(find.text('Change provider'), findsOneWidget);
  });
}

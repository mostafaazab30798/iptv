import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/shared/widgets/shimmer.dart';

void main() {
  testWidgets('reduced motion renders shimmer content without a shader', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Shimmer(child: SizedBox(key: ValueKey('content'))),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('content')), findsOneWidget);
    expect(find.byType(ShaderMask), findsNothing);
  });
}

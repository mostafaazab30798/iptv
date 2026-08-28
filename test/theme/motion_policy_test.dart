import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/app/theme/app_motion.dart';

void main() {
  testWidgets(
    'motion policy returns zero durations when animations are disabled',
    (tester) async {
      late MotionPolicy policy;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                policy = MotionPolicy.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(policy.fast, Duration.zero);
      expect(policy.standard, Duration.zero);
      expect(policy.slow, Duration.zero);
      expect(policy.focus, Duration.zero);
    },
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/analytics/analytics_policy.dart';

void main() {
  group('AnalyticsPolicy', () {
    test('allows safe properties', () {
      expect(AnalyticsPolicy.isPropertyAllowed('reason', 'trial_expired'), isTrue);
      expect(AnalyticsPolicy.isPropertyAllowed('foreground', true), isTrue);
    });

    test('rejects forbidden IPTV and credential keys', () {
      expect(AnalyticsPolicy.isPropertyAllowed('serverUrl', 'x'), isFalse);
      expect(AnalyticsPolicy.isPropertyAllowed('password', 'secret'), isFalse);
      expect(AnalyticsPolicy.isPropertyAllowed('stream_url', 'x'), isFalse);
      expect(AnalyticsPolicy.isPropertyAllowed('email', 'a@b.c'), isFalse);
    });

    test('rejects URL-like string values', () {
      expect(
        AnalyticsPolicy.isPropertyAllowed('note', 'https://example.com/x'),
        isFalse,
      );
    });
  });
}

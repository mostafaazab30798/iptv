import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/analytics/installation_marker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('InstallationMarker.claimFirstOpen', () {
    test('returns true on the very first call', () async {
      final marker = InstallationMarker();
      expect(await marker.claimFirstOpen(), isTrue);
    });

    test('returns false on subsequent calls within the same instance', () async {
      final marker = InstallationMarker();
      await marker.claimFirstOpen();
      expect(await marker.claimFirstOpen(), isFalse);
    });

    test('returns false on a new instance after the marker has been written', () async {
      // Simulate app restart: create a fresh instance backed by the same prefs.
      final prefs = await SharedPreferences.getInstance();
      final marker1 = InstallationMarker(prefs: prefs);
      await marker1.claimFirstOpen();

      final marker2 = InstallationMarker(prefs: prefs);
      expect(await marker2.claimFirstOpen(), isFalse);
    });

    test('resetForTesting clears the marker', () async {
      final prefs = await SharedPreferences.getInstance();
      final marker = InstallationMarker(prefs: prefs);
      await marker.claimFirstOpen();
      await marker.resetForTesting();
      expect(await marker.claimFirstOpen(), isTrue);
    });
  });

  group('InstallationMarker.claimVersionChange', () {
    test('returns null on first ever launch (no previous version)', () async {
      final marker = InstallationMarker();
      expect(await marker.claimVersionChange('1.0.0'), isNull);
    });

    test('returns null when version is unchanged', () async {
      final prefs = await SharedPreferences.getInstance();
      final marker1 = InstallationMarker(prefs: prefs);
      await marker1.claimVersionChange('1.0.0');

      final marker2 = InstallationMarker(prefs: prefs);
      expect(await marker2.claimVersionChange('1.0.0'), isNull);
    });

    test('returns the previous version when version changes', () async {
      final prefs = await SharedPreferences.getInstance();
      final marker1 = InstallationMarker(prefs: prefs);
      await marker1.claimVersionChange('1.0.0');

      final marker2 = InstallationMarker(prefs: prefs);
      final previous = await marker2.claimVersionChange('1.1.0');
      expect(previous, equals('1.0.0'));
    });

    test('emits only once per version change, not on every launch at same version', () async {
      final prefs = await SharedPreferences.getInstance();
      final marker1 = InstallationMarker(prefs: prefs);
      await marker1.claimVersionChange('1.0.0');
      await marker1.claimVersionChange('1.1.0'); // upgrade

      // Same version on next launch:
      final marker2 = InstallationMarker(prefs: prefs);
      expect(await marker2.claimVersionChange('1.1.0'), isNull);
    });
  });
}

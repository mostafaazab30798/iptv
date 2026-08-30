import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/app/router.dart';

void main() {
  group('routeRedirectForSession', () {
    test('valid IPTV session escapes the access-required screen', () {
      expect(
        routeRedirectForSession(
          location: Routes.accessRequired,
          iptvAuthenticated: true,
          appAccountSignedIn: true,
        ),
        Routes.home,
      );
    });

    test('valid IPTV session can use normal app routes without entitlement', () {
      expect(
        routeRedirectForSession(
          location: Routes.settings,
          iptvAuthenticated: true,
          appAccountSignedIn: false,
        ),
        isNull,
      );
    });

    test('server setup is available without a HOPE TV account', () {
      expect(
        routeRedirectForSession(
          location: Routes.onboarding,
          iptvAuthenticated: false,
          appAccountSignedIn: false,
        ),
        isNull,
      );
    });

    test('protected IPTV routes require provider credentials only', () {
      expect(
        routeRedirectForSession(
          location: Routes.home,
          iptvAuthenticated: false,
          appAccountSignedIn: true,
        ),
        Routes.onboarding,
      );
    });

    test('account management still asks for HOPE TV sign-in', () {
      expect(
        routeRedirectForSession(
          location: Routes.account,
          iptvAuthenticated: true,
          appAccountSignedIn: false,
        ),
        Routes.signIn,
      );
    });

    test('gate can be explicitly re-enabled in a future build', () {
      expect(
        routeRedirectForSession(
          location: Routes.home,
          iptvAuthenticated: true,
          appAccountSignedIn: true,
          accessGateEnabled: true,
          entitlementAllowsPremium: false,
          entitlementLoading: false,
        ),
        Routes.accessRequired,
      );
    });
  });
}

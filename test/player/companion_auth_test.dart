import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/player/handoff/domain/audio_handoff_models.dart';

void main() {
  group('Companion Auth Handoff Domain Models', () {
    test('CompanionAuthHandoffInfo encodes and decodes QR payload cleanly', () {
      const info = CompanionAuthHandoffInfo(
        hostIp: '192.168.1.120',
        port: 8998,
        sessionToken: 'test_token_xyz987',
        pinCode: '4829',
        targetDeviceName: 'Living Room Android TV',
      );

      final qrString = info.toQrPayload();
      expect(qrString, contains('act=auth_handoff'));
      expect(qrString, contains('ip=192.168.1.120'));
      expect(qrString, contains('p=8998'));
      expect(qrString, contains('tok=test_token_xyz987'));
      expect(qrString, contains('pin=4829'));

      // 1. Decode from HTTP URL
      final decodedFromUrl = CompanionAuthHandoffInfo.fromQrPayload(qrString);
      expect(decodedFromUrl, isNotNull);
      expect(decodedFromUrl!.hostIp, '192.168.1.120');
      expect(decodedFromUrl.port, 8998);
      expect(decodedFromUrl.sessionToken, 'test_token_xyz987');
      expect(decodedFromUrl.pinCode, '4829');
      expect(decodedFromUrl.targetDeviceName, 'Living Room Android TV');

      // 2. Decode from JSON payload
      const jsonPayload =
          '{"act":"auth_handoff","ip":"192.168.1.120","p":8998,"tok":"json_token_123","pin":"7391","dev":"Bedroom TV"}';
      final decodedFromJson =
          CompanionAuthHandoffInfo.fromQrPayload(jsonPayload);
      expect(decodedFromJson, isNotNull);
      expect(decodedFromJson!.hostIp, '192.168.1.120');
      expect(decodedFromJson.port, 8998);
      expect(decodedFromJson.sessionToken, 'json_token_123');
      expect(decodedFromJson.pinCode, '7391');
      expect(decodedFromJson.targetDeviceName, 'Bedroom TV');
    });

    test('Regular Audio Handoff does not mistakenly parse Auth Handoff QR', () {
      const authInfo = CompanionAuthHandoffInfo(
        hostIp: '192.168.1.120',
        port: 8998,
        sessionToken: 'test_token_xyz987',
        pinCode: '4829',
        targetDeviceName: 'Living Room Android TV',
      );

      final qrString = authInfo.toQrPayload();
      final audioSession = HandoffSessionInfo.fromQrPayload(qrString);
      expect(audioSession, isNull);
    });

    test('CompanionAuthCredentialsPayload encodes and decodes JSON correctly', () {
      const payload = CompanionAuthCredentialsPayload(
        token: 'auth_token_456',
        pin: '1234',
        serverUrl: 'http://xtream.example.com:8080',
        username: 'user_john',
        password: 'secret_password_123',
        email: 'john@example.com',
        refreshToken: 'refresh_tok_abc',
        companionDeviceName: 'Pixel 8 Pro',
      );

      final json = payload.toJson();
      final iptv = json['iptv'] as Map<String, dynamic>;
      final account = json['account'] as Map<String, dynamic>;
      expect(json['type'], 'auth_transfer');
      expect(json['tok'], 'auth_token_456');
      expect(json['pin'], '1234');
      expect(iptv['url'], 'http://xtream.example.com:8080');
      expect(iptv['user'], 'user_john');
      expect(iptv['pass'], 'secret_password_123');
      expect(account['email'], 'john@example.com');
      expect(account['refresh_token'], 'refresh_tok_abc');
      expect(json['dev'], 'Pixel 8 Pro');

      final decoded = CompanionAuthCredentialsPayload.fromJson(json);
      expect(decoded.token, 'auth_token_456');
      expect(decoded.pin, '1234');
      expect(decoded.serverUrl, 'http://xtream.example.com:8080');
      expect(decoded.username, 'user_john');
      expect(decoded.password, 'secret_password_123');
      expect(decoded.email, 'john@example.com');
      expect(decoded.refreshToken, 'refresh_tok_abc');
      expect(decoded.companionDeviceName, 'Pixel 8 Pro');
    });
  });

  group('Reordered Auth Route Redirect Rules', () {
    test('Unauthenticated fresh user routes to Onboarding first', () {
      final redirect = routeRedirectForSession(
        location: Routes.splash,
        iptvAuthenticated: false,
        appAccountSignedIn: false,
        accessGateEnabled: true,
      );
      expect(redirect, Routes.onboarding);
    });

    test('Unauthenticated user already on Onboarding stays on Onboarding', () {
      final redirect = routeRedirectForSession(
        location: Routes.onboarding,
        iptvAuthenticated: false,
        appAccountSignedIn: false,
        accessGateEnabled: true,
      );
      expect(redirect, isNull);
    });

    test(
        'User with valid IPTV but not signed into app account is redirected to signIn when accessing home',
        () {
      final redirect = routeRedirectForSession(
        location: Routes.home,
        iptvAuthenticated: true,
        appAccountSignedIn: false,
        accessGateEnabled: true,
      );
      expect(redirect, Routes.signIn);
    });

    test(
        'User on onboarding is always allowed on onboarding even if IPTV credentials were saved',
        () {
      final redirect = routeRedirectForSession(
        location: Routes.onboarding,
        iptvAuthenticated: true,
        appAccountSignedIn: false,
        accessGateEnabled: true,
      );
      expect(redirect, isNull);
    });

    test('User with valid IPTV on signIn or verifyCode stays there', () {
      final redirectSignIn = routeRedirectForSession(
        location: Routes.signIn,
        iptvAuthenticated: true,
        appAccountSignedIn: false,
        accessGateEnabled: true,
      );
      expect(redirectSignIn, isNull);

      final redirectVerify = routeRedirectForSession(
        location: Routes.verifyCode,
        iptvAuthenticated: true,
        appAccountSignedIn: false,
        accessGateEnabled: true,
      );
      expect(redirectVerify, isNull);
    });

    test(
        'User with both IPTV and app account signed in redirects from auth/onboarding to home',
        () {
      final redirect = routeRedirectForSession(
        location: Routes.onboarding,
        iptvAuthenticated: true,
        appAccountSignedIn: true,
        accessGateEnabled: true,
        entitlementAllowsPremium: true,
      );
      expect(redirect, Routes.home);

      final redirectFromSignIn = routeRedirectForSession(
        location: Routes.signIn,
        iptvAuthenticated: true,
        appAccountSignedIn: true,
        accessGateEnabled: true,
        entitlementAllowsPremium: true,
      );
      expect(redirectFromSignIn, Routes.home);
    });

    test('Access gate disabled routes directly to home once IPTV is authenticated', () {
      final redirect = routeRedirectForSession(
        location: Routes.onboarding,
        iptvAuthenticated: true,
        appAccountSignedIn: false,
        accessGateEnabled: false,
      );
      expect(redirect, Routes.home);
    });
  });
}

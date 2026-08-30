import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/releases/release_manifest.dart';
import 'package:iptv/core/releases/release_verifier.dart';

/// Integration check: live production manifest verifies with embedded public key.
///
/// Run manually after configuring release signing:
///   flutter test test/updates/production_manifest_integration_test.dart \
///     --dart-define-from-file=secrets/release-signing/release-public-keys.json
///
/// Or pass RELEASE_PUBLIC_KEYS_JSON directly from GitHub secret value.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('production version manifest verifies with RELEASE_PUBLIC_KEYS_JSON', () async {
    const keysJson = String.fromEnvironment('RELEASE_PUBLIC_KEYS_JSON');
    if (keysJson.isEmpty || keysJson == '{}') {
      // Allow local file fallback when running verify script on owner machine.
      final file = File('secrets/release-signing/release-public-keys.json');
      if (!file.existsSync()) {
        return; // skip when keys not available in CI
      }
      final decoded = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      await _verifyLiveManifest(
        decoded.map((k, v) => MapEntry('$k', '$v')),
      );
      return;
    }

    final decoded = jsonDecode(keysJson) as Map<String, dynamic>;
    await _verifyLiveManifest(
      decoded.map((k, v) => MapEntry('$k', '$v')),
    );
  });
}

Future<void> _verifyLiveManifest(Map<String, String> publicKeys) async {
  const baseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://otmovtxevvuxbsrmurkb.supabase.co',
  );
  const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  final anon = anonKey.isNotEmpty
      ? anonKey
      : Platform.environment['SUPABASE_ANON_KEY'] ?? '';

  if (anon.isEmpty) {
    // Skip without credentials — unit tests cover verifier logic.
    return;
  }

  final uri = Uri.parse(
    '$baseUrl/functions/v1/version?platform=android&architecture=arm64-v8a&buildNumber=0&channel=stable',
  );
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    request.headers.set('apikey', anon);
    request.headers.set('Authorization', 'Bearer $anon');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    expect(response.statusCode, 200);

    final payload = jsonDecode(body) as Map<String, dynamic>;
    final manifestJson = payload['manifest'];
    expect(manifestJson, isA<Map>());

    final verifier = ReleaseVerifier(ed25519PublicKeysById: publicKeys);
    final manifest = ReleaseManifest.fromJson(
      Map<String, dynamic>.from(manifestJson as Map),
    );
    await expectLater(verifier.verify(manifest), completes);
  } finally {
    client.close(force: true);
  }
}

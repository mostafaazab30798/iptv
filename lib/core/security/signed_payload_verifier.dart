import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:iptv/core/commercial/commercial_api_config.dart';

class LeaseVerificationException implements Exception {
  LeaseVerificationException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => 'LeaseVerificationException($code): $message';
}

/// Verifies signed offline entitlement leases.
///
/// Production: Ed25519 public keys by keyId.
/// Local/dev only: optional HMAC secret via dart-define (never for production builds).
class SignedPayloadVerifier {
  SignedPayloadVerifier({
    Map<String, String>? ed25519PublicKeysById,
    String? hmacSecret,
  })  : _ed25519PublicKeysById =
            ed25519PublicKeysById ?? CommercialApiConfig.entitlementPublicKeys,
        _hmacSecret =
            hmacSecret ?? CommercialApiConfig.entitlementHmacVerifySecret;

  final Map<String, String> _ed25519PublicKeysById;
  final String? _hmacSecret;

  static const audience = 'hope-tv-player';

  Future<Map<String, dynamic>> verifyLease({
    required String payloadB64Url,
    required String signatureB64Url,
    required String keyId,
    required String expectedDeviceId,
    required DateTime nowUtc,
  }) async {
    final payloadBytes = _fromBase64Url(payloadB64Url);
    final signatureBytes = _fromBase64Url(signatureB64Url);

    var verified = false;

    final pubHex = _ed25519PublicKeysById[keyId];
    if (pubHex != null &&
        pubHex.isNotEmpty &&
        !pubHex.startsWith('PLACEHOLDER')) {
      final algorithm = Ed25519();
      final publicKey = SimplePublicKey(
        _hexToBytes(pubHex),
        type: KeyPairType.ed25519,
      );
      verified = await algorithm.verify(
        payloadBytes,
        signature: Signature(signatureBytes, publicKey: publicKey),
      );
    }

    if (!verified &&
        _hmacSecret != null &&
        _hmacSecret.isNotEmpty &&
        !_hmacSecret.startsWith('PLACEHOLDER')) {
      verified = _hmacSha256Verify(_hmacSecret, payloadBytes, signatureBytes);
    }

    if (!verified) {
      throw LeaseVerificationException(
        'invalid_signature',
        'Lease signature could not be verified.',
      );
    }

    final claims = jsonDecode(utf8.decode(payloadBytes)) as Map<String, dynamic>;
    if (claims['aud'] != audience) {
      throw LeaseVerificationException('bad_audience', 'Lease audience mismatch.');
    }
    if (claims['deviceId'] != expectedDeviceId) {
      throw LeaseVerificationException('bad_device', 'Lease device mismatch.');
    }
    final exp = claims['exp'];
    if (exp is! num) {
      throw LeaseVerificationException('bad_exp', 'Lease expiration missing.');
    }
    if (exp.toInt() * 1000 <= nowUtc.millisecondsSinceEpoch) {
      throw LeaseVerificationException('expired', 'Offline lease expired.');
    }
    return claims;
  }

  bool _hmacSha256Verify(String secret, List<int> payload, List<int> signature) {
    final digest = crypto.Hmac(crypto.sha256, utf8.encode(secret)).convert(payload);
    final expected = Uint8List.fromList(digest.bytes);
    if (expected.length != signature.length) return false;
    var diff = 0;
    for (var i = 0; i < expected.length; i++) {
      diff |= expected[i] ^ signature[i];
    }
    return diff == 0;
  }

  static Uint8List _fromBase64Url(String value) {
    final padded = value.replaceAll('-', '+').replaceAll('_', '/');
    final pad = padded.length % 4 == 0 ? '' : '=' * (4 - padded.length % 4);
    return Uint8List.fromList(base64Decode(padded + pad));
  }

  static Uint8List _hexToBytes(String hex) {
    final clean = hex.trim().toLowerCase().replaceFirst(RegExp(r'^0x'), '');
    final out = Uint8List(clean.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }
}

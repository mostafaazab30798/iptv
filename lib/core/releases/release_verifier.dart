import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:iptv/core/commercial/commercial_api_config.dart';
import 'package:iptv/core/releases/release_manifest.dart';

class ReleaseVerificationException implements Exception {
  ReleaseVerificationException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => 'ReleaseVerificationException($code): $message';
}

/// Verifies signed release manifests before presenting update UX.
class ReleaseVerifier {
  ReleaseVerifier({
    Map<String, String>? ed25519PublicKeysById,
    String? hmacSecret,
  })  : _ed25519PublicKeysById =
            ed25519PublicKeysById ?? CommercialApiConfig.releasePublicKeys,
        _hmacSecret = hmacSecret ?? CommercialApiConfig.releaseHmacVerifySecret;

  final Map<String, String> _ed25519PublicKeysById;
  final String? _hmacSecret;

  Future<ReleaseManifest> verify(ReleaseManifest manifest) async {
    if (manifest.sha256.isEmpty || manifest.sha256.startsWith('PLACEHOLDER')) {
      throw ReleaseVerificationException(
        'invalid_digest',
        'Release digest is not configured.',
      );
    }

    final payloadB64 = _toBase64Url(utf8.encode(manifest.canonicalJson()));
    final signatureBytes = _fromBase64Url(manifest.signature);
    var verified = false;

    final pubHex = _ed25519PublicKeysById[manifest.keyId];
    if (pubHex != null && pubHex.isNotEmpty && !pubHex.startsWith('PLACEHOLDER')) {
      final algorithm = Ed25519();
      final publicKey = SimplePublicKey(
        _hexToBytes(pubHex),
        type: KeyPairType.ed25519,
      );
      verified = await algorithm.verify(
        utf8.encode(payloadB64),
        signature: Signature(signatureBytes, publicKey: publicKey),
      );
    }

    if (!verified &&
        _hmacSecret != null &&
        _hmacSecret.isNotEmpty &&
        !_hmacSecret.startsWith('PLACEHOLDER')) {
      verified = _hmacSha256Verify(_hmacSecret, utf8.encode(payloadB64), signatureBytes);
    }

    if (!verified) {
      throw ReleaseVerificationException(
        'invalid_signature',
        'Release manifest signature could not be verified.',
      );
    }

    return manifest;
  }

  bool verifyFileDigest(List<int> bytes, String expectedSha256Hex) {
    final digest = crypto.sha256.convert(bytes).toString();
    return digest.toLowerCase() == expectedSha256Hex.toLowerCase();
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

  static String _toBase64Url(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
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

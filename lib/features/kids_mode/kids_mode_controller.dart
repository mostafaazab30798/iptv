import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/features/kids_mode/kids_mode_state.dart';
import 'package:iptv/features/kids_mode/kids_mode_storage.dart';

enum KidsPinResult {
  success,
  invalidPin,
  invalidFormat,
  lockedOut,
  unavailable,
}

class KidsModeController extends StateNotifier<KidsModeState> {
  KidsModeController(this._storage) : super(const KidsModeState()) {
    unawaited(initialize());
  }

  final KidsModeStorage _storage;
  String? _pinSalt;
  String? _pinVerifier;

  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(seconds: 30);
  static final RegExp _validPin = RegExp(r'^\d{4}$');
  static final Pbkdf2 _pinKdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 120000,
    bits: 256,
  );

  Future<void> initialize() async {
    try {
      final config = await _storage.load();
      _pinSalt = config.pinSalt;
      _pinVerifier = config.pinVerifier;
      state = KidsModeState(
        isInitialized: true,
        isEnabled: config.enabled,
        hasPin: config.hasPin,
      );
    } catch (e) {
      // Fail closed if the saved mode cannot be read. This avoids briefly
      // exposing the unrestricted catalog during a storage failure.
      state = KidsModeState(
        isInitialized: true,
        isEnabled: true,
        error: e.toString(),
      );
    }
  }

  Future<KidsPinResult> enableWithNewPin(String pin) async {
    if (!_validPin.hasMatch(pin)) return KidsPinResult.invalidFormat;

    final saltBytes = List<int>.generate(
      16,
      (_) => Random.secure().nextInt(256),
    );
    final salt = base64UrlEncode(saltBytes);
    final verifier = await _deriveVerifier(pin, salt);

    try {
      await _storage.savePin(salt: salt, verifier: verifier);
      await _storage.setEnabled(true);
      _pinSalt = salt;
      _pinVerifier = verifier;
      state = state.copyWith(
        isInitialized: true,
        isEnabled: true,
        hasPin: true,
        failedAttempts: 0,
        clearLockout: true,
        clearError: true,
      );
      return KidsPinResult.success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return KidsPinResult.unavailable;
    }
  }

  Future<KidsPinResult> enableWithExistingPin(String pin) async {
    final result = await verifyPin(pin);
    if (result != KidsPinResult.success) return result;
    try {
      await _storage.setEnabled(true);
      state = state.copyWith(isEnabled: true, clearError: true);
      return KidsPinResult.success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return KidsPinResult.unavailable;
    }
  }

  Future<KidsPinResult> disable(String pin) async {
    final result = await verifyPin(pin);
    if (result != KidsPinResult.success) return result;
    try {
      await _storage.setEnabled(false);
      state = state.copyWith(isEnabled: false, clearError: true);
      return KidsPinResult.success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return KidsPinResult.unavailable;
    }
  }

  Future<KidsPinResult> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    final result = await verifyPin(currentPin);
    if (result != KidsPinResult.success) return result;
    if (!_validPin.hasMatch(newPin)) return KidsPinResult.invalidFormat;

    final wasEnabled = state.isEnabled;
    final update = await enableWithNewPin(newPin);
    if (update == KidsPinResult.success && !wasEnabled) {
      await _storage.setEnabled(false);
      state = state.copyWith(isEnabled: false);
    }
    return update;
  }

  Future<KidsPinResult> verifyPin(String pin) async {
    if (state.isLockedOut) return KidsPinResult.lockedOut;
    if (!_validPin.hasMatch(pin)) return KidsPinResult.invalidFormat;
    final salt = _pinSalt;
    final expected = _pinVerifier;
    if (salt == null || expected == null) return KidsPinResult.unavailable;

    final actual = await _deriveVerifier(pin, salt);
    if (_constantTimeEquals(actual, expected)) {
      state = state.copyWith(
        failedAttempts: 0,
        clearLockout: true,
        clearError: true,
      );
      return KidsPinResult.success;
    }

    final attempts = state.failedAttempts + 1;
    if (attempts >= _maxFailedAttempts) {
      state = state.copyWith(
        failedAttempts: 0,
        lockoutUntil: DateTime.now().add(_lockoutDuration),
      );
      return KidsPinResult.lockedOut;
    }
    state = state.copyWith(failedAttempts: attempts);
    return KidsPinResult.invalidPin;
  }

  static Future<String> _deriveVerifier(String pin, String salt) async {
    final key = await _pinKdf.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: base64Url.decode(salt),
    );
    return base64UrlEncode(await key.extractBytes());
  }

  static bool _constantTimeEquals(String left, String right) {
    final a = utf8.encode(left);
    final b = utf8.encode(right);
    var difference = a.length ^ b.length;
    final length = min(a.length, b.length);
    for (var i = 0; i < length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }
}

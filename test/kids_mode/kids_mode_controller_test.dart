import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/features/kids_mode/kids_mode_controller.dart';
import 'package:iptv/features/kids_mode/kids_mode_storage.dart';

class _MemoryKidsModeStorage implements KidsModeStorage {
  bool enabled = false;
  String? salt;
  String? verifier;

  @override
  Future<StoredKidsModeConfig> load() async => StoredKidsModeConfig(
    enabled: enabled,
    pinSalt: salt,
    pinVerifier: verifier,
  );

  @override
  Future<void> savePin({required String salt, required String verifier}) async {
    this.salt = salt;
    this.verifier = verifier;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    this.enabled = enabled;
  }
}

void main() {
  test(
    'first enable creates a verifier and requires the PIN to disable',
    () async {
      final storage = _MemoryKidsModeStorage();
      final controller = KidsModeController(storage);
      await controller.initialize();

      expect(await controller.enableWithNewPin('1234'), KidsPinResult.success);
      expect(controller.state.isEnabled, isTrue);
      expect(controller.state.hasPin, isTrue);
      expect(storage.verifier, isNot('1234'));

      expect(await controller.disable('9999'), KidsPinResult.invalidPin);
      expect(controller.state.isEnabled, isTrue);
      expect(await controller.disable('1234'), KidsPinResult.success);
      expect(controller.state.isEnabled, isFalse);
    },
  );

  test('rejects non-numeric and non-4-digit PIN values', () async {
    final controller = KidsModeController(_MemoryKidsModeStorage());
    await controller.initialize();

    expect(
      await controller.enableWithNewPin('123'),
      KidsPinResult.invalidFormat,
    );
    expect(
      await controller.enableWithNewPin('12345'),
      KidsPinResult.invalidFormat,
    );
    expect(
      await controller.enableWithNewPin('abcd'),
      KidsPinResult.invalidFormat,
    );
  });

  test('changing the PIN invalidates the previous PIN', () async {
    final controller = KidsModeController(_MemoryKidsModeStorage());
    await controller.initialize();
    await controller.enableWithNewPin('1234');

    expect(
      await controller.changePin(currentPin: '1234', newPin: '5678'),
      KidsPinResult.success,
    );
    expect(await controller.verifyPin('1234'), KidsPinResult.invalidPin);
    expect(await controller.verifyPin('5678'), KidsPinResult.success);
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/releases/release_manifest.dart';
import 'package:iptv/domain/repositories/release_repository.dart';
import 'package:iptv/features/updates/update_controller.dart';
import 'package:iptv/features/updates/update_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeReleaseRepository implements ReleaseRepository {
  _FakeReleaseRepository(this.onCheck);

  final Future<ReleaseCheckResult> Function() onCheck;
  int checkCount = 0;

  @override
  Future<ReleaseCheckResult> checkForUpdate() {
    checkCount++;
    return onCheck();
  }

  @override
  Future<DownloadAuthorization> authorizeDownload(String releaseId) {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<UpdatePreferences> preferences() async {
    final prefs = await SharedPreferences.getInstance();
    return UpdatePreferences(preferences: prefs);
  }

  test('manual check exposes not-configured status in Settings', () async {
    final repository = _FakeReleaseRepository(
      () async => const ReleaseCheckResult(updateAvailable: false),
    );
    final controller = UpdateController(
      repository,
      preferences: await preferences(),
      isConfigured: () => false,
      supportsUpdates: () => true,
    );

    await controller.checkForUpdates(force: true);

    expect(controller.state.status, UpdateFlowStatus.notConfigured);
    expect(repository.checkCount, 0);
    controller.dispose();
  });

  test('successful manual check reports installed build and up-to-date', () async {
    final repository = _FakeReleaseRepository(
      () async => const ReleaseCheckResult(
        updateAvailable: false,
        installedBuildNumber: 9,
      ),
    );
    final controller = UpdateController(
      repository,
      preferences: await preferences(),
      isConfigured: () => true,
      supportsUpdates: () => true,
    );

    await controller.checkForUpdates(force: true);

    expect(controller.state.status, UpdateFlowStatus.upToDate);
    expect(controller.state.installedBuildNumber, 9);
    expect(repository.checkCount, 1);
    controller.dispose();
  });

  test('concurrent update checks share one network request', () async {
    final result = Completer<ReleaseCheckResult>();
    final repository = _FakeReleaseRepository(() => result.future);
    final controller = UpdateController(
      repository,
      preferences: await preferences(),
      isConfigured: () => true,
      supportsUpdates: () => true,
    );

    final first = controller.checkForUpdates(force: true);
    final second = controller.checkForUpdates(force: true);
    expect(repository.checkCount, 1);
    expect(controller.state.status, UpdateFlowStatus.checking);

    result.complete(
      const ReleaseCheckResult(
        updateAvailable: false,
        installedBuildNumber: 9,
      ),
    );
    await Future.wait([first, second]);

    expect(repository.checkCount, 1);
    expect(controller.state.status, UpdateFlowStatus.upToDate);
    controller.dispose();
  });
}

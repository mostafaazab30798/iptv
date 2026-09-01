import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/core/releases/release_manifest.dart';
import 'package:iptv/domain/repositories/release_repository.dart';
import 'package:iptv/features/updates/update_controller.dart';
import 'package:iptv/features/updates/update_dialog.dart';
import 'package:iptv/features/updates/update_preferences.dart';
import 'package:iptv/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeReleaseRepository implements ReleaseRepository {
  _FakeReleaseRepository({this.result});

  final ReleaseCheckResult? result;

  @override
  Future<ReleaseCheckResult> checkForUpdate() async {
    return result ?? const ReleaseCheckResult(updateAvailable: false);
  }

  @override
  Future<DownloadAuthorization> authorizeDownload(String releaseId) async {
    return DownloadAuthorization(
      downloadUrl:
          'https://github.com/test/repo/releases/download/v1.0.0/app.apk',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      releaseId: releaseId,
    );
  }
}

ReleaseManifest _sampleManifest({
  bool mandatory = false,
  String version = '2.1.0',
  int buildNumber = 42,
  int fileSize = 25 * 1024 * 1024,
  String? notesEn = '• Fixed player playback issues\n• Added enhanced subtitles',
  String? notesAr,
}) {
  return ReleaseManifest(
    schemaVersion: 1,
    platform: 'android',
    architecture: 'arm64-v8a',
    channel: 'stable',
    version: version,
    buildNumber: buildNumber,
    minimumSupportedVersion: '1.0.0',
    mandatory: mandatory,
    fileSize: fileSize,
    sha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    downloadAuthorizationPath: '/v1/downloads/authorize',
    publishedAt: '2026-09-01T12:00:00Z',
    releaseNotesEn: notesEn,
    releaseNotesAr: notesAr,
    keyId: 'key-1',
    signature: 'sig',
  );
}

Widget _wrapWithApp(Widget child, ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      locale: const Locale('en'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('showUpdateDialogIfNeeded displays optional update dialog with badges & release notes',
      (tester) async {
    final manifest = _sampleManifest();
    final repo = _FakeReleaseRepository(
      result: ReleaseCheckResult(
        updateAvailable: true,
        releaseId: 'rel-123',
        manifest: manifest,
        installedBuildNumber: 10,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final updatePrefs = UpdatePreferences(preferences: prefs);

    final container = ProviderContainer(
      overrides: [
        releaseRepositoryProvider.overrideWithValue(repo),
        updateProvider.overrideWith((ref) {
          final controller = UpdateController(
            repo,
            preferences: updatePrefs,
            isConfigured: () => true,
            supportsUpdates: () => true,
          );
          return controller;
        }),
      ],
    );

    // Populate update state
    await container.read(updateProvider.notifier).checkForUpdates(force: true);

    await tester.pumpWidget(
      _wrapWithApp(
        Consumer(
          builder: (context, ref, _) {
            return ElevatedButton(
              onPressed: () => showUpdateDialogIfNeeded(context, ref),
              child: const Text('Check Updates'),
            );
          },
        ),
        container,
      ),
    );

    // Tap button to trigger dialog
    await tester.tap(find.text('Check Updates'));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('Update available'), findsOneWidget);
    expect(find.text('v2.1.0'), findsOneWidget);
    expect(find.text('Build 42'), findsOneWidget);
    expect(find.text('25.0 MB'), findsOneWidget);
    expect(find.text("What's New"), findsOneWidget);
    expect(find.textContaining('Fixed player playback issues'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    expect(find.text('Download update'), findsOneWidget);

    // Dismiss with Later
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();

    expect(find.text('Update available'), findsNothing);
  });

  testWidgets('showUpdateDialogIfNeeded displays mandatory update screen when mandatory = true',
      (tester) async {
    final manifest = _sampleManifest(mandatory: true, version: '3.0.0', buildNumber: 99);
    final repo = _FakeReleaseRepository(
      result: ReleaseCheckResult(
        updateAvailable: true,
        releaseId: 'rel-mandatory',
        manifest: manifest,
        installedBuildNumber: 10,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final updatePrefs = UpdatePreferences(preferences: prefs);

    final container = ProviderContainer(
      overrides: [
        releaseRepositoryProvider.overrideWithValue(repo),
        updateProvider.overrideWith((ref) {
          return UpdateController(
            repo,
            preferences: updatePrefs,
            isConfigured: () => true,
            supportsUpdates: () => true,
          );
        }),
      ],
    );

    await container.read(updateProvider.notifier).checkForUpdates(force: true);

    await tester.pumpWidget(
      _wrapWithApp(
        Consumer(
          builder: (context, ref, _) {
            return ElevatedButton(
              onPressed: () => showUpdateDialogIfNeeded(context, ref),
              child: const Text('Show'),
            );
          },
        ),
        container,
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('v3.0.0'), findsOneWidget);
    expect(find.text('Build 99'), findsOneWidget);
    expect(find.text('Download update'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

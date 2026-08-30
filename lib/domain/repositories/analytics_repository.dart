import 'package:iptv/core/analytics/analytics_event.dart';

abstract class AnalyticsRepository {
  Future<void> track(
    AnalyticsEventName name, {
    Map<String, Object?> properties,
  });

  Future<void> start({String? deviceId});
  Future<void> stop();
  Future<void> flush();

  /// Updates the device ID after registration completes post-start.
  /// Triggers the first heartbeat if not yet sent.
  void updateDeviceId(String? deviceId);
}

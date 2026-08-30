import 'package:iptv/core/analytics/analytics_client.dart';
import 'package:iptv/core/analytics/analytics_event.dart';
import 'package:iptv/domain/repositories/analytics_repository.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  AnalyticsRepositoryImpl({AnalyticsClient? client})
      : _client = client ?? AnalyticsClient();

  final AnalyticsClient _client;

  @override
  Future<void> track(
    AnalyticsEventName name, {
    Map<String, Object?> properties = const {},
  }) =>
      _client.track(name, properties: properties);

  @override
  Future<void> start({String? deviceId}) => _client.start(deviceId: deviceId);

  @override
  Future<void> stop() => _client.stop();

  @override
  Future<void> flush() => _client.flush();

  @override
  void updateDeviceId(String? deviceId) => _client.updateDeviceId(deviceId);
}

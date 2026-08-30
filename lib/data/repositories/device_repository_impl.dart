import 'package:iptv/core/commercial/commercial_edge_functions_client.dart';
import 'package:iptv/core/constants/app_constants.dart';
import 'package:iptv/core/identity/current_device_store.dart';
import 'package:iptv/core/identity/installation_identity.dart';
import 'package:iptv/domain/entities/app_device.dart';
import 'package:iptv/domain/repositories/device_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl({
    required InstallationIdentity installationIdentity,
    CurrentDeviceStore? deviceStore,
    CommercialEdgeFunctionsClient? edgeClient,
  })  : _identity = installationIdentity,
        _deviceStore = deviceStore ?? CurrentDeviceStore(),
        _edge = edgeClient ?? CommercialEdgeFunctionsClient();

  final InstallationIdentity _identity;
  final CurrentDeviceStore _deviceStore;
  final CommercialEdgeFunctionsClient _edge;

  @override
  Future<String?> currentDeviceId() => _deviceStore.read();

  @override
  Future<({int deviceLimit, List<AppDevice> devices})> listDevices() async {
    final payload = await _edge.invoke('devices');
    final limit = (payload['deviceLimit'] as num?)?.toInt() ?? 3;
    final raw = payload['devices'];
    final devices = <AppDevice>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          devices.add(AppDevice.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return (deviceLimit: limit, devices: devices);
  }

  @override
  Future<String> registerCurrentDevice({
    String? displayName,
    String? appVersion,
  }) async {
    final hash = await _identity.getInstallationIdHash();
    final platform = _identity.platformCode();
    final payload = await _edge.invoke(
      'devices',
      method: HttpMethod.post,
      body: {
        'action': 'register',
        'installationIdHash': hash,
        'platform': platform,
        'displayName': displayName ?? 'HOPE TV ($platform)',
        'appVersion': appVersion ?? AppConstants.appVersion,
        'osVersionCategory': platform,
      },
    );
    final id = payload['deviceId'] as String?;
    if (id == null || id.isEmpty) {
      throw StateError('Device registration did not return a device id.');
    }
    await _deviceStore.save(id);
    return id;
  }

  @override
  Future<void> revokeDevice(String deviceId) async {
    await _edge.invoke(
      'devices',
      method: HttpMethod.post,
      body: {
        'action': 'revoke',
        'deviceId': deviceId,
      },
    );
    final current = await _deviceStore.read();
    if (current == deviceId) {
      await _deviceStore.clear();
    }
  }
}

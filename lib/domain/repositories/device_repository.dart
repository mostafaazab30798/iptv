import 'package:iptv/domain/entities/app_device.dart';

abstract class DeviceRepository {
  Future<({int deviceLimit, List<AppDevice> devices})> listDevices();

  Future<String?> currentDeviceId();

  Future<String> registerCurrentDevice({
    String? displayName,
    String? appVersion,
  });

  Future<void> revokeDevice(String deviceId);
}

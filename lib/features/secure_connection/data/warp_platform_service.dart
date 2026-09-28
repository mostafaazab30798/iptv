import 'package:flutter/services.dart';

/// Native capabilities exposed by the official Cloudflare WARP application.
abstract interface class WarpPlatformService {
  Future<bool> isInstalled();

  Future<bool> openWarp();

  Future<void> openStore();

  Future<bool> isVpnActive();
}

/// Android implementation backed by HOPE's narrow platform channel.
final class MethodChannelWarpPlatformService implements WarpPlatformService {
  MethodChannelWarpPlatformService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('hope_iptv/warp');

  final MethodChannel _channel;

  @override
  Future<bool> isInstalled() => _invokeBool('isInstalled');

  @override
  Future<bool> isVpnActive() => _invokeBool('getVpnState');

  @override
  Future<bool> openWarp() => _invokeBool('openWarp');

  @override
  Future<void> openStore() => _channel.invokeMethod<void>('openStore');

  Future<bool> _invokeBool(String method) async {
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}

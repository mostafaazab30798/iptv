import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Monitors network reachability.
class NetworkStatus {
  NetworkStatus._();

  static NetworkStatus? _instance;
  static NetworkStatus get instance {
    _instance ??= NetworkStatus._();
    return _instance!;
  }

  final Connectivity _connectivity = Connectivity();

  /// Whether the device currently has any network connectivity.
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Stream of connectivity changes.
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );
}

/// Riverpod provider for reactive network status.
final networkStatusProvider = StreamProvider<bool>((ref) {
  return NetworkStatus.instance.onConnectivityChanged;
});

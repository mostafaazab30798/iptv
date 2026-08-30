import 'package:iptv/core/commercial/commercial_api_config.dart';
import 'package:iptv/core/commercial/supabase_secure_auth_storage.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes the dedicated commercial Supabase client (never the IPTV ApiClient).
class SupabaseClientFactory {
  SupabaseClientFactory._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<bool> ensureInitialized() async {
    if (_initialized) return true;
    if (!CommercialApiConfig.isConfigured) {
      AppLogger.info(
        'Commercial Supabase not configured (placeholders). App account auth disabled until dart-defines are set.',
        feature: 'commercial',
      );
      return false;
    }

    await Supabase.initialize(
      url: CommercialApiConfig.supabaseUrl,
      // ignore: deprecated_member_use — publishableKey alias; anonKey still supported.
      anonKey: CommercialApiConfig.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: SupabaseSecureAuthStorage(),
        autoRefreshToken: true,
      ),
    );
    _initialized = true;
    AppLogger.info('Commercial Supabase initialized', feature: 'commercial');
    return true;
  }

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError('Supabase commercial client is not initialized.');
    }
    return Supabase.instance.client;
  }
}

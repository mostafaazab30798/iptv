import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/core/commercial/supabase_client_factory.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin client for commercial Edge Functions (fixed Supabase origin only).
class CommercialEdgeFunctionsClient {
  CommercialEdgeFunctionsClient();

  Future<Map<String, dynamic>> invoke(
    String functionName, {
    HttpMethod method = HttpMethod.get,
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool requireSession = true,
  }) async {
    final ok = await SupabaseClientFactory.ensureInitialized();
    if (!ok) {
      throw StateError('Commercial Supabase client is not configured.');
    }
    final client = SupabaseClientFactory.client;
    if (requireSession && client.auth.currentSession == null) {
      throw StateError('Not signed in to app account.');
    }

    final response = await client.functions.invoke(
      functionName,
      method: method,
      body: body,
      queryParameters: queryParameters,
    );

    final status = response.status;
    final data = response.data;
    Map<String, dynamic> decoded = {};
    if (data is Map<String, dynamic>) {
      decoded = data;
    } else if (data is Map) {
      decoded = Map<String, dynamic>.from(data);
    }

    if (status < 200 || status >= 300) {
      final err = decoded['error'];
      final message = err is Map && err['message'] is String
          ? err['message'] as String
          : 'Commercial API request failed ($status).';
      final code = err is Map && err['code'] is String
          ? err['code'] as String
          : 'commercial_api_error';
      AppLogger.error(
        'Edge function $functionName failed: $code',
        feature: 'commercial',
      );
      throw CommercialApiException(code: code, message: message, status: status);
    }

    return decoded;
  }
}

class CommercialApiException implements Exception {
  CommercialApiException({
    required this.code,
    required this.message,
    required this.status,
  });

  final String code;
  final String message;
  final int status;

  @override
  String toString() => 'CommercialApiException($code): $message';
}

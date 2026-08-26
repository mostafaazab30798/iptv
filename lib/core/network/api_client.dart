import 'dart:convert';
import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:iptv/core/constants/api_constants.dart';
import 'package:iptv/core/errors/app_error.dart';
import 'package:iptv/core/network/api_config.dart';
import 'package:iptv/core/network/api_exception.dart';
import 'package:iptv/core/network/interceptors/auth_interceptor.dart';

/// Central HTTP client for all IPTV API calls.
///
/// Converts responses safely even if server sends `text/html` or `text/plain` headers.
class ApiClient {
  ApiClient(ApiConfig config) {
    var base = config.baseUrl.trim();
    if (!base.startsWith('http://') && !base.startsWith('https://')) {
      base = 'http://$base';
    }
    if (!base.endsWith('/')) {
      base = '$base/';
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: base,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.sendTimeout,
        responseType: ResponseType.plain,
        headers: {
          'Accept': '*/*',
          if (!kIsWeb)
            ApiConstants.userAgentHeader: ApiConstants.defaultUserAgent,
        },
        followRedirects: true,
        validateStatus: (status) => status != null && status < 500,
      ),
    )..interceptors.add(AuthInterceptor(config));
  }

  late final Dio _dio;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? params,
    T Function(dynamic json)? fromJson,
    CancelToken? cancelToken,
  }) async {
    try {
      final cleanPath = path.startsWith('/') ? path.substring(1) : path;
      final response = await _dio.get<dynamic>(
        cleanPath,
        queryParameters: params,
        cancelToken: cancelToken,
      );
      return await _parse<T>(response.data, fromJson);
    } on DioException catch (e) {
      dev.log(
        'DioException on GET $path: type=${e.type}, message=${e.message}, error=${e.error}, statusCode=${e.response?.statusCode}',
        name: 'ApiClient',
        error: e,
      );
      throw ApiException(_translateDioError(e));
    } catch (e) {
      dev.log('Exception on GET $path: $e', name: 'ApiClient', error: e);
      if (e is ApiException) rethrow;
      throw ApiException(NetworkError(message: e.toString(), cause: e));
    }
  }

  Future<T> post<T>(
    String path, {
    Map<String, dynamic>? data,
    T Function(dynamic json)? fromJson,
    CancelToken? cancelToken,
  }) async {
    try {
      final cleanPath = path.startsWith('/') ? path.substring(1) : path;
      final response = await _dio.post<dynamic>(
        cleanPath,
        data: data,
        cancelToken: cancelToken,
      );
      return await _parse<T>(response.data, fromJson);
    } on DioException catch (e) {
      dev.log(
        'DioException on POST $path: type=${e.type}, message=${e.message}, error=${e.error}, statusCode=${e.response?.statusCode}',
        name: 'ApiClient',
        error: e,
      );
      throw ApiException(_translateDioError(e));
    }
  }

  void close() => _dio.close(force: true);

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<T> _parse<T>(dynamic rawData, T Function(dynamic)? fromJson) async {
    dynamic data = rawData;

    // Decode plain text if returned as String
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) {
        data = (T == List || T.toString().startsWith('List<')) ? <dynamic>[] : <String, dynamic>{};
      } else if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          // Use a background isolate for large payloads (>50KB) to avoid blocking frame
          // rendering when Xtream panels return 10k–20k stream entries (several MB JSON).
          if (trimmed.length > 50000) {
            data = await compute<String, Object?>(_decodeJson, trimmed);
          } else {
            data = jsonDecode(trimmed);
          }
        } catch (e) {
          dev.log('JSON decode failed: $e. Raw preview: ${trimmed.take(100)}', name: 'ApiClient');
        }
      }
    }

    if (fromJson != null) return fromJson(data);

    if (data is T) return data;

    // Handle generic collections
    if (data is List) {
      if (T == List || T.toString().startsWith('List<')) {
        return data as T;
      }
    }

    if (data is Map) {
      if (T == Map || T.toString().startsWith('Map<')) {
        return Map<String, dynamic>.from(data) as T;
      }
      // If server returned {} when a List was expected (empty result)
      if (T == List || T.toString().startsWith('List<')) {
        return <dynamic>[] as T;
      }
    }

    if (data == null) {
      if (T == List || T.toString().startsWith('List<')) {
        return <dynamic>[] as T;
      }
      if (T == Map || T.toString().startsWith('Map<')) {
        return <String, dynamic>{} as T;
      }
    }

    throw ApiException(
      ParsingError(message: 'Unexpected response type: ${data.runtimeType} (expected $T)'),
    );
  }

  AppError _translateDioError(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        TimeoutError(message: 'Connection timed out. Check your server address and port.', cause: e),
      DioExceptionType.badResponse => _translateStatusCode(
          e.response?.statusCode ?? 0, e),
      DioExceptionType.cancel =>
        NetworkError(message: 'Request cancelled', cause: e),
      DioExceptionType.connectionError =>
        NetworkError(
          message: e.error != null
              ? 'Could not connect to server: ${e.error}'
              : 'Could not connect to server. Check server address, port, or internet connection.',
          cause: e,
        ),
      _ => NetworkError(
          message: e.message ?? e.error?.toString() ?? 'Network connection error',
          cause: e,
        ),
    };
  }

  AppError _translateStatusCode(int code, DioException e) {
    return switch (code) {
      401 || 403 =>
        AuthenticationError(message: 'Invalid username or password.', cause: e),
      >= 500 =>
        ServerError(message: 'Server error ($code). Server may be offline.', statusCode: code, cause: e),
      _ =>
        NetworkError(message: 'HTTP $code error', cause: e),
    };
  }
}

extension on String {
  String take(int n) => length <= n ? this : substring(0, n);
}

/// Top-level function required by [compute] — isolate entry points must be
/// top-level (or static) and match ComputeCallback(String, Object?).
Object? _decodeJson(String source) => jsonDecode(source);


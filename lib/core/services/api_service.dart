import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import 'storage_service.dart';

final storageServiceProvider = Provider((_) => StorageService());

final dioProvider = Provider((ref) {
  final storage = ref.read(storageServiceProvider);
  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Accept': 'application/json'},
  ));

  dio.interceptors.add(_AuthInterceptor(dio, storage));

  return dio;
});

/// Interceptor that:
/// 1. Attaches the bearer token to every request.
/// 2. On 401, attempts a token refresh via /auth/refresh ONCE.
///    If the refresh succeeds, retries the original request with the new
///    token. If the refresh also 401s, clears the token (session expired).
/// 3. Extracts human-readable error messages from Laravel's JSON body.
class _AuthInterceptor extends InterceptorsWrapper {
  final Dio _dio;
  final StorageService _storage;
  bool _isRefreshing = false;

  _AuthInterceptor(this._dio, this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    debugPrint('[DIO] ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('[DIO] ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) async {
    final statusCode = error.response?.statusCode;
    debugPrint('[DIO ERROR] $statusCode ${error.requestOptions.uri}');
    debugPrint('[DIO ERROR] body: ${error.response?.data}');

    // ── Auto-refresh on 401 ────────────────────────────────────────────
    if (statusCode == 401 && !_isRefreshing) {
      final isRefreshCall = error.requestOptions.path == ApiConstants.refresh;
      final isLoginCall = error.requestOptions.path == ApiConstants.login;

      // Don't retry refresh or login endpoints themselves.
      if (!isRefreshCall && !isLoginCall) {
        _isRefreshing = true;
        try {
          final currentToken = await _storage.getToken();
          if (currentToken != null) {
            // Try refreshing with a fresh Dio instance (not the intercepted one)
            // to avoid recursion.
            final refreshDio = Dio(BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $currentToken',
              },
            ));
            final refreshResponse =
                await refreshDio.post(ApiConstants.refresh);

            if (refreshResponse.statusCode == 200) {
              final data = refreshResponse.data as Map<String, dynamic>;
              final newToken = data['token'] as String?;
              if (newToken != null) {
                await _storage.saveToken(newToken);

                // Update saved profile token too.
                final profiles = await _storage.getSavedProfiles();
                for (final p in profiles) {
                  if (p.token == currentToken) {
                    await _storage.saveProfile(SavedProfile(
                      userId: p.userId,
                      name: p.name,
                      email: p.email,
                      avatar: p.avatar,
                      primaryRole: p.primaryRole,
                      token: newToken,
                      savedAt: DateTime.now(),
                    ));
                    break;
                  }
                }

                debugPrint('[DIO] Token refreshed, retrying original request');

                // Retry original request with new token.
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';
                final retryResponse = await _dio.fetch(opts);
                _isRefreshing = false;
                return handler.resolve(retryResponse);
              }
            }
          }
        } catch (refreshError) {
          debugPrint('[DIO] Token refresh failed: $refreshError');
        }
        _isRefreshing = false;
      }

      // If we got here, refresh failed or wasn't attempted — clear token.
      await _storage.deleteToken();
      debugPrint('[DIO] 401 received – token cleared');
    }

    // ── Extract readable message ────────────────────────────────────────
    final data = error.response?.data;
    String? serverMessage;
    if (data is Map) {
      serverMessage = data['message'] as String? ?? data['error'] as String?;
    }

    if (serverMessage != null) {
      handler.reject(
        DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          type: error.type,
          error: serverMessage,
          message: serverMessage,
        ),
      );
    } else {
      handler.next(error);
    }
  }
}

/// Extracts the best human-readable error string from a [DioException] or
/// any other exception.
String extractErrorMessage(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'] ?? data['error'];
      if (msg != null) return msg.toString();
    }
    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 400) return 'Data yang dikirim tidak valid (400).';
      if (statusCode == 401) return 'Email atau password salah.';
      if (statusCode == 403) return 'Akses ditolak (403).';
      if (statusCode == 404) return 'Layanan tidak ditemukan (404).';
      if (statusCode == 500) return 'Terjadi kesalahan pada server (500).';
      return 'Terjadi kesalahan HTTP ($statusCode).';
    }
    
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa jaringan Anda.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server.';
      default:
        return 'Terjadi kesalahan jaringan atau koneksi.';
    }
  }
  return e.toString();
}

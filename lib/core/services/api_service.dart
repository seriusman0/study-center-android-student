import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../providers/maintenance_provider.dart';
import 'storage_service.dart';

import 'cache_service.dart';
import 'cache_helper.dart';

final storageServiceProvider = Provider((_) => StorageService());
final cacheServiceProvider = Provider((_) => CacheService());

final dioProvider = Provider((ref) {
  final storage = ref.read(storageServiceProvider);
  final cache = ref.read(cacheServiceProvider);
  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10), // Reduced timeout for faster offline detection
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Accept': 'application/json'},
  ));

  dio.interceptors.add(_AuthInterceptor(dio, storage, ref));
  dio.interceptors.add(_CacheInterceptor(cache));

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
  final ProviderRef _ref;
  bool _isRefreshing = false;

  _AuthInterceptor(this._dio, this._storage, this._ref);

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

    // ── Maintenance Check ────────────────────────────────────────
    if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
      _ref.read(maintenanceProvider.notifier).setMaintenance(true);
    }

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
            
            String? newToken;
            
            try {
              final refreshResponse = await refreshDio.post(ApiConstants.refresh);
              if (refreshResponse.statusCode == 200) {
                newToken = (refreshResponse.data as Map<String, dynamic>)['token'] as String?;
              }
            } catch (e) {
              debugPrint('[DIO] /auth/refresh failed, trying silent login...');
            }

            if (newToken == null) {
              final profiles = await _storage.getSavedProfiles();
              SavedProfile? currentProfile;
              for (final p in profiles) {
                if (p.token == currentToken) {
                  currentProfile = p;
                  break;
                }
              }

              if (currentProfile != null && currentProfile.password != null && currentProfile.password!.isNotEmpty) {
                final loginDio = Dio(BaseOptions(
                  baseUrl: ApiConstants.baseUrl,
                  connectTimeout: const Duration(seconds: 30),
                  receiveTimeout: const Duration(seconds: 30),
                  headers: {'Accept': 'application/json'},
                ));
                try {
                  final loginRes = await loginDio.post(ApiConstants.login, data: {
                    'email': currentProfile.email,
                    'password': currentProfile.password,
                  });
                  if (loginRes.statusCode == 200 || loginRes.statusCode == 201) {
                    newToken = loginRes.data['token'] as String?;
                  }
                } catch (e) {
                  debugPrint('[DIO] Silent login failed: $e');
                }
              }
            }

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
                    password: p.password, // Keep password
                    savedAt: DateTime.now(),
                  ));
                  break;
                }
              }

              debugPrint('[DIO] Token refreshed/logged in silently, retrying original request');

              // Retry original request with new token.
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newToken';
              final retryResponse = await _dio.fetch(opts);
              _isRefreshing = false;
              return handler.resolve(retryResponse);
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
      final isOfflineError = error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.unknown;
          
      if (isOfflineError) {
        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            type: error.type,
            error: 'Anda sedang offline. Koneksi internet diperlukan.',
            message: 'Anda sedang offline. Koneksi internet diperlukan.',
          ),
        );
      } else {
        handler.next(error);
      }
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
        return e.message ?? 'Koneksi timeout. Periksa jaringan Anda.';
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return (e.error is String) ? e.error as String : (e.message ?? 'Tidak dapat terhubung ke server.');
      default:
        return (e.error is String) ? e.error as String : (e.message ?? 'Terjadi kesalahan jaringan atau koneksi.');
    }
  }
  return e.toString();
}

class _CacheInterceptor extends Interceptor {
  final CacheService _cache;

  _CacheInterceptor(this._cache);

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (response.requestOptions.method == 'GET' && response.statusCode == 200) {
      final url = response.requestOptions.uri.toString();
      if (response.data is Map<String, dynamic>) {
        await _cache.saveCache(url, response.data as Map<String, dynamic>);
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.requestOptions.method == 'GET') {
      final isOfflineError = err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.connectionError ||
          err.type == DioExceptionType.receiveTimeout ||
          err.type == DioExceptionType.unknown;
          
      if (isOfflineError) {
        final url = err.requestOptions.uri.toString();
        final cachedData = await _cache.getCache(url);
        if (cachedData != null) {
          debugPrint('[DIO CACHE] Returning cached data for $url');
          return handler.resolve(
            Response(
              requestOptions: err.requestOptions,
              data: cachedData,
              statusCode: 200,
            ),
          );
        } else {
          // If offline and not cached directly, try template fallback for journal
          if (url.contains('/today?date=')) {
            final uri = Uri.parse(url);
            final targetDate = uri.queryParameters['date'];
            if (targetDate != null) {
              final prefix = url.split('?').first;
              final latestCache = await _cache.getLatestCacheByPrefix(prefix);
              if (latestCache != null) {
                final template = generateOfflineTemplate(latestCache, targetDate);
                debugPrint('[DIO CACHE] Returning template for $url based on latest cache');
                return handler.resolve(
                  Response(
                    requestOptions: err.requestOptions,
                    data: template,
                    statusCode: 200,
                  ),
                );
              }
            }
          }

          // If offline and not cached, reject with a friendly message.
          return handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              type: err.type,
              error: 'Data belum tersimpan di memori lokal.',
              message: 'Data belum tersimpan di memori lokal.',
            ),
          );
        }
      }
    }
    handler.next(err);
  }
}

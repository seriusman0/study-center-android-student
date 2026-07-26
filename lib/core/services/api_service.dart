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
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Accept': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      debugPrint('[DIO] ${options.method} ${options.uri}');
      handler.next(options);
    },
    onResponse: (response, handler) {
      debugPrint('[DIO] ${response.statusCode} ${response.requestOptions.uri}');
      handler.next(response);
    },
    onError: (error, handler) async {
      final statusCode = error.response?.statusCode;
      debugPrint('[DIO ERROR] $statusCode ${error.requestOptions.uri}');
      debugPrint('[DIO ERROR] body: ${error.response?.data}');

      if (statusCode == 401) {
        // Clear stored token on 401 so session restore doesn't loop
        await storage.deleteToken();
        debugPrint('[DIO] 401 received – token cleared');
      }

      // Surface a readable message instead of raw DioException
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
    },
  ));

  return dio;
});

/// Extracts the best human-readable error string from a [DioException] or
/// any other exception.
String extractErrorMessage(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'] ?? data['error'];
      if (msg != null) return msg.toString();
    }
    if (e.message != null && e.message!.isNotEmpty) return e.message!;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa jaringan Anda.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server.';
      default:
        return 'Terjadi kesalahan jaringan.';
    }
  }
  return e.toString();
}

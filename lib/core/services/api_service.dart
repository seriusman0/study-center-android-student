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
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
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
    onError: (error, handler) {
      debugPrint('[DIO ERROR] ${error.response?.statusCode} ${error.requestOptions.uri}');
      debugPrint('[DIO ERROR] body: ${error.response?.data}');
      handler.next(error);
    },
  ));

  return dio;
});

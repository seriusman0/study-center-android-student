import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/user_model.dart';

class AccessDeniedException implements Exception {
  const AccessDeniedException();
}

class AuthRepository {
  final Dio _dio;
  final StorageService _storage;

  const AuthRepository(this._dio, this._storage);

  Future<UserModel> login(String email, String password) async {
    final response = await _dio.post(ApiConstants.login, data: {
      'email': email,
      'password': password,
    });

    final data = response.data as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    if (!user.isStudent) throw const AccessDeniedException();

    await _storage.saveToken(data['token'] as String);
    return user;
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(ApiConstants.register, data: {
      'name': name,
      'email': email,
      'password': password,
    });

    final data = response.data as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    await _storage.saveToken(data['token'] as String);
    return user;
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } finally {
      await _storage.deleteToken();
    }
  }

  Future<UserModel> me() async {
    final response = await _dio.get(ApiConstants.me);
    final data = response.data as Map<String, dynamic>;
    return UserModel.fromJson(data['user'] ?? data);
  }
}

final authRepositoryProvider = Provider((ref) => AuthRepository(
      ref.read(dioProvider),
      ref.read(storageServiceProvider),
    ));

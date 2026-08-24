import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final Dio _dio;
  final StorageService _storage;

  const AuthRepository(this._dio, this._storage);

  Future<UserModel> login(String login, String password) async {
    final response = await _dio.post(ApiConstants.login, data: {
      'login': login,
      'password': password,
    });

    final data = response.data as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token'] as String;

    // All 7 backend roles are allowed to sign in — the app's navigation
    // shell adapts its tabs and home content per role.
    await _storage.saveToken(token);

    // Persist profile for quick-switch on next app launch.
    await _storage.saveProfile(SavedProfile(
      userId: user.id,
      name: user.name,
      email: user.email,
      avatar: user.avatar,
      primaryRole: user.primaryRole,
      token: token,
      savedAt: DateTime.now(),
    ));

    return user;
  }

  /// Restore a session from a previously-saved profile token.
  /// Calls GET /me to verify the token is still valid; if so, refreshes
  /// the saved profile with the latest user data.
  Future<UserModel> loginWithToken(SavedProfile profile) async {
    // Set the token first so the Dio interceptor attaches it.
    await _storage.saveToken(profile.token);

    try {
      final user = await me();

      // Refresh profile snapshot with latest server data.
      await _storage.saveProfile(SavedProfile(
        userId: user.id,
        name: user.name,
        email: user.email,
        avatar: user.avatar,
        primaryRole: user.primaryRole,
        token: profile.token,
        savedAt: DateTime.now(),
      ));

      return user;
    } catch (_) {
      // Token expired/revoked — clear it so we don't loop.
      await _storage.deleteToken();
      rethrow;
    }
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
    final token = data['token'] as String;

    await _storage.saveToken(token);

    await _storage.saveProfile(SavedProfile(
      userId: user.id,
      name: user.name,
      email: user.email,
      avatar: user.avatar,
      primaryRole: user.primaryRole,
      token: token,
      savedAt: DateTime.now(),
    ));

    return user;
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } finally {
      await _storage.deleteToken();
      // Note: we do NOT remove the saved profile on logout — the user
      // should still see it in the quick-switch list next time.
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

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

class AdminUsersRepository {
  final Dio _dio;
  const AdminUsersRepository(this._dio);

  Future<List<UserModel>> fetchUsers({String? query, String? role, int page = 1}) async {
    final response = await _dio.get(ApiConstants.adminUsers, queryParameters: {
      if (query != null && query.isNotEmpty) 'q': query,
      if (role != null && role.isNotEmpty) 'role': role,
      'page': page,
    });
    final data = response.data as Map<String, dynamic>;
    final list = (data['data'] as List?) ?? [];
    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateRole(int userId, String role) async {
    await _dio.patch(ApiConstants.adminUserRole(userId), data: {'role': role});
  }

  Future<void> toggleActive(int userId) async {
    await _dio.patch(ApiConstants.adminUserToggleActive(userId));
  }
}

final adminUsersRepositoryProvider = Provider((ref) => AdminUsersRepository(ref.read(dioProvider)));

class AdminUsersState {
  final bool loading;
  final List<UserModel> users;
  final String? error;
  final String query;
  final String? roleFilter;

  const AdminUsersState({
    this.loading = false,
    this.users = const [],
    this.error,
    this.query = '',
    this.roleFilter,
  });

  AdminUsersState copyWith({
    bool? loading,
    List<UserModel>? users,
    String? error,
    String? query,
    String? roleFilter,
    bool clearRoleFilter = false,
  }) =>
      AdminUsersState(
        loading: loading ?? this.loading,
        users: users ?? this.users,
        error: error,
        query: query ?? this.query,
        roleFilter: clearRoleFilter ? null : (roleFilter ?? this.roleFilter),
      );
}

class AdminUsersNotifier extends Notifier<AdminUsersState> {
  @override
  AdminUsersState build() => const AdminUsersState();

  Future<void> load({String? query, String? role, bool clearRole = false}) async {
    state = state.copyWith(
      loading: true,
      error: null,
      query: query,
      roleFilter: role,
      clearRoleFilter: clearRole,
    );
    try {
      final users = await ref.read(adminUsersRepositoryProvider).fetchUsers(
            query: state.query,
            role: state.roleFilter,
          );
      state = state.copyWith(loading: false, users: users);
    } catch (e) {
      state = state.copyWith(loading: false, error: extractErrorMessage(e));
    }
  }

  Future<bool> updateRole(int userId, String role) async {
    try {
      await ref.read(adminUsersRepositoryProvider).updateRole(userId, role);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleActive(int userId) async {
    try {
      await ref.read(adminUsersRepositoryProvider).toggleActive(userId);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> impersonate(int userId) async {
    try {
      state = state.copyWith(loading: true);
      final response = await ref.read(dioProvider).post('/admin/users/$userId/impersonate');
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      
      final storage = ref.read(storageServiceProvider);
      
      final currentAuth = ref.read(authProvider);
      if (currentAuth.user != null) {
          final adminToken = await storage.getToken();
          if (adminToken != null) {
              await storage.saveProfile(SavedProfile(
                  userId: currentAuth.user!.id,
                  name: currentAuth.user!.name,
                  email: currentAuth.user!.email,
                  avatar: currentAuth.user!.avatar,
                  primaryRole: currentAuth.user!.primaryRole,
                  token: adminToken,
                  savedAt: DateTime.now(),
              ));
          }
      }
      
      await storage.saveToken(token);
      ref.read(authProvider.notifier).setUser(user);
      
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: extractErrorMessage(e));
      return false;
    }
  }
}

final adminUsersProvider = NotifierProvider<AdminUsersNotifier, AdminUsersState>(AdminUsersNotifier.new);

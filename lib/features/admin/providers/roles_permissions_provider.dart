import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/role_permission_model.dart';

class RolesPermissionsRepository {
  final Dio _dio;
  const RolesPermissionsRepository(this._dio);

  Future<List<RoleModel>> fetchRoles() async {
    final response = await _dio.get(ApiConstants.adminRoles);
    final data = response.data as Map<String, dynamic>;
    final list = (data['data'] as List?) ?? [];
    return list.map((e) => RoleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PermissionModel>> fetchPermissions() async {
    final response = await _dio.get(ApiConstants.adminPermissions);
    final data = response.data as Map<String, dynamic>;
    final list = (data['data'] as List?) ?? [];
    return list.map((e) => PermissionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RoleModel> createRole({required String name, String? description}) async {
    final response = await _dio.post(ApiConstants.adminRoles, data: {
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
    });
    final data = response.data as Map<String, dynamic>;
    return RoleModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<RoleModel> updateRole(int id, {required String name, String? description}) async {
    final response = await _dio.put(ApiConstants.adminRoleDetail(id), data: {
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
    });
    final data = response.data as Map<String, dynamic>;
    return RoleModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Sync (replace) the full set of permission IDs assigned to a role.
  Future<RoleModel> syncPermissions(int roleId, List<int> permissionIds) async {
    final response = await _dio.post(ApiConstants.adminRolePermissions(roleId), data: {
      'permissions': permissionIds,
    });
    final data = response.data as Map<String, dynamic>;
    return RoleModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteRole(int id) async {
    await _dio.delete(ApiConstants.adminRoleDetail(id));
  }
}

final rolesPermissionsRepositoryProvider =
    Provider((ref) => RolesPermissionsRepository(ref.read(dioProvider)));

class RolesPermissionsState {
  final bool loading;
  final List<RoleModel> roles;
  final List<PermissionModel> permissions;
  final String? error;

  const RolesPermissionsState({
    this.loading = false,
    this.roles = const [],
    this.permissions = const [],
    this.error,
  });

  RolesPermissionsState copyWith({
    bool? loading,
    List<RoleModel>? roles,
    List<PermissionModel>? permissions,
    String? error,
  }) =>
      RolesPermissionsState(
        loading: loading ?? this.loading,
        roles: roles ?? this.roles,
        permissions: permissions ?? this.permissions,
        error: error,
      );
}

class RolesPermissionsNotifier extends Notifier<RolesPermissionsState> {
  @override
  RolesPermissionsState build() => const RolesPermissionsState();

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final repo = ref.read(rolesPermissionsRepositoryProvider);
      final results = await Future.wait([repo.fetchRoles(), repo.fetchPermissions()]);
      state = state.copyWith(
        loading: false,
        roles: results[0] as List<RoleModel>,
        permissions: results[1] as List<PermissionModel>,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: extractErrorMessage(e));
    }
  }

  Future<bool> createRole({required String name, String? description}) async {
    try {
      await ref.read(rolesPermissionsRepositoryProvider).createRole(name: name, description: description);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateRole(int id, {required String name, String? description}) async {
    try {
      await ref.read(rolesPermissionsRepositoryProvider).updateRole(id, name: name, description: description);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> syncPermissions(int roleId, List<int> permissionIds) async {
    try {
      await ref.read(rolesPermissionsRepositoryProvider).syncPermissions(roleId, permissionIds);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteRole(int id) async {
    try {
      await ref.read(rolesPermissionsRepositoryProvider).deleteRole(id);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final rolesPermissionsProvider =
    NotifierProvider<RolesPermissionsNotifier, RolesPermissionsState>(RolesPermissionsNotifier.new);

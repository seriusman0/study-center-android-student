class PermissionModel {
  final int id;
  final String name;
  final String? description;
  final int rolesCount;

  const PermissionModel({
    required this.id,
    required this.name,
    this.description,
    this.rolesCount = 0,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      rolesCount: (json['roles_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class RoleModel {
  final int id;
  final String name;
  final String? description;
  final int usersCount;
  final List<PermissionModel> permissions;

  const RoleModel({
    required this.id,
    required this.name,
    this.description,
    this.usersCount = 0,
    this.permissions = const [],
  });

  /// IDs of the permissions currently assigned to this role — handy for
  /// pre-checking the checkbox list in the edit sheet.
  Set<int> get permissionIds => permissions.map((p) => p.id).toSet();

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    final permsRaw = json['permissions'] as List? ?? [];
    return RoleModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      usersCount: (json['users_count'] as num?)?.toInt() ?? 0,
      permissions: permsRaw
          .map((e) => PermissionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

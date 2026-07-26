class UserModel {
  final int id;
  final String name;
  final String username;
  final String email;
  final String? avatar;
  final String? cabang;
  final String? cabangSlug;
  final List<String> roles;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.avatar,
    this.cabang,
    this.cabangSlug,
    required this.roles,
  });

  bool get isStudent => roles.contains('student');

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'] as List? ?? [];
    return UserModel(
      id:         (json['id'] as num).toInt(),
      name:       json['name'] as String? ?? '',
      username:   json['username'] as String? ?? '',
      email:      json['email'] as String? ?? '',
      avatar:     json['avatar'] as String?,
      cabang:     (json['cabang'] as Map?)?['nama'] as String?,
      cabangSlug: (json['cabang'] as Map?)?['slug'] as String?,
      roles: rolesRaw
          .map((r) => (r is Map ? r['name'] : r) as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }
}

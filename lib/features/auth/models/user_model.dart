class UserModel {
  final int id;
  final String name;
  final String username;
  final String email;
  final String? avatar;
  final int? cabangId;
  final String? cabang;
  final String? cabangSlug;
  final List<String> roles;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.avatar,
    this.cabangId,
    this.cabang,
    this.cabangSlug,
    required this.roles,
  });

  bool get isStudent => roles.contains('student');

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'] as List? ?? [];
    final cabangObj = json['cabang'] as Map?;
    return UserModel(
      id:         (json['id'] as num).toInt(),
      name:       json['name'] as String? ?? '',
      username:   json['username'] as String? ?? '',
      email:      json['email'] as String? ?? '',
      avatar:     json['avatar'] as String?,
      // `cabang_id` is present directly on the user object too (FK column),
      // fall back to the nested cabang.id if needed.
      cabangId:   (json['cabang_id'] as num?)?.toInt() ?? (cabangObj?['id'] as num?)?.toInt(),
      cabang:     cabangObj?['nama'] as String?,
      cabangSlug: cabangObj?['slug'] as String?,
      roles: rolesRaw
          .map((r) => (r is Map ? r['name'] : r) as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }
}

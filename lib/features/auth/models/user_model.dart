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
  final bool isActive;

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
    this.isActive = true,
  });

  bool get isStudent => roles.contains('student');
  bool get isAdmin => roles.contains('admin');
  bool get isMentor => roles.contains('mentor');
  bool get isFulltimer => roles.contains('fulltimer');
  bool get isGuest => roles.contains('guest');
  bool get isScholarshipTeenager => roles.contains('scholarship_teenager');
  bool get isCollege => roles.contains('college');

  /// Roles that see the student-style bottom nav (Beranda/Jurnal/Laporan/Profil)
  /// with journal + laporan + galeri student endpoints.
  bool get hasStudentDashboard => isStudent || isScholarshipTeenager;

  /// Roles that have access to journal API (/api/jurnal/*)
  bool get hasJournalAccess => isStudent || isCollege || isScholarshipTeenager;

  /// True if user has multiple roles
  bool get hasMultipleRoles => roles.length > 1;

  /// Roles that can manage kelas/presensi (mentor tooling).
  bool get hasMentorTools => isMentor || isAdmin;

  /// Primary role label for display/routing purposes — first matching role
  /// in priority order (a user can technically have multiple role rows).
  String get primaryRole {
    if (isAdmin) return 'admin';
    if (isMentor) return 'mentor';
    if (isFulltimer) return 'fulltimer';
    if (isStudent) return 'student';
    if (isScholarshipTeenager) return 'scholarship_teenager';
    if (isCollege) return 'college';
    if (isGuest) return 'guest';
    return roles.isNotEmpty ? roles.first : 'guest';
  }

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
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

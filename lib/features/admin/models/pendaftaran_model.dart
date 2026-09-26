/// A student registration (pendaftaran) awaiting admin validation.
/// Mirrors User + nested student_profile + cabang from
/// PendaftaranAdminApiController.
class PendaftaranItem {
  final int id;
  final String name;
  final String username;
  final String? avatar;
  final int? cabangId;
  final String? cabangNama;
  final bool isActive;
  final DateTime? createdAt;
  final PendaftaranStudentProfile? profile;

  const PendaftaranItem({
    required this.id,
    required this.name,
    required this.username,
    this.avatar,
    this.cabangId,
    this.cabangNama,
    required this.isActive,
    this.createdAt,
    this.profile,
  });

  factory PendaftaranItem.fromJson(Map<String, dynamic> json) {
    final cabang = json['cabang'] as Map<String, dynamic>?;
    final profileJson = json['student_profile'] as Map<String, dynamic>?;
    return PendaftaranItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatar: json['avatar'] as String?,
      cabangId: (json['cabang_id'] as num?)?.toInt(),
      cabangNama: cabang?['nama'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      profile: profileJson != null ? PendaftaranStudentProfile.fromJson(profileJson) : null,
    );
  }
}

class PendaftaranStudentProfile {
  final int id;
  final String? birthDate;
  final String? birthPlace;
  final String? gender;
  final String? address;
  final String? guardianName;
  final String? guardianPhone;
  final String? studentPhone;
  final String? photo;
  final String? note;
  final List<String> mataPelajaran;
  final bool isPending;
  final String status; // pending | diterima | ditolak | perbaikan
  final String? catatanAdmin;
  final String? schoolName;
  final String? gradeClass;
  final int? entryYear;

  const PendaftaranStudentProfile({
    required this.id,
    this.birthDate,
    this.birthPlace,
    this.gender,
    this.address,
    this.guardianName,
    this.guardianPhone,
    this.studentPhone,
    this.photo,
    this.note,
    required this.mataPelajaran,
    required this.isPending,
    required this.status,
    this.catatanAdmin,
    this.schoolName,
    this.gradeClass,
    this.entryYear,
  });

  factory PendaftaranStudentProfile.fromJson(Map<String, dynamic> json) {
    final mapelRaw = json['mata_pelajaran'];
    return PendaftaranStudentProfile(
      id: (json['id'] as num).toInt(),
      birthDate: json['birth_date'] as String?,
      birthPlace: json['birth_place'] as String?,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      guardianName: json['guardian_name'] as String?,
      guardianPhone: json['guardian_phone'] as String?,
      studentPhone: json['student_phone'] as String?,
      photo: json['photo'] as String?,
      note: json['note'] as String?,
      mataPelajaran: mapelRaw is List ? mapelRaw.map((e) => e.toString()).toList() : [],
      isPending: (json['is_pending'] == true) || (json['is_pending'] == 1),
      status: json['status'] as String? ?? 'pending',
      catatanAdmin: json['catatan_admin'] as String?,
      schoolName: json['school_name'] as String?,
      gradeClass: json['grade_class'] as String?,
      entryYear: (json['entry_year'] as num?)?.toInt(),
    );
  }
}

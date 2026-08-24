/// Certificate template — a reusable HTML layout admins design once and
/// issue certificates from (see CertificateTemplateApiController).
class CertificateTemplate {
  final int id;
  final String nama;
  final String? deskripsi;
  final String htmlContent;
  final String orientation; // portrait | landscape
  final String paperSize; // a4
  final String? logoPath;
  final bool isActive;
  final String? creatorName;
  final DateTime? createdAt;

  const CertificateTemplate({
    required this.id,
    required this.nama,
    this.deskripsi,
    required this.htmlContent,
    required this.orientation,
    required this.paperSize,
    this.logoPath,
    required this.isActive,
    this.creatorName,
    this.createdAt,
  });

  factory CertificateTemplate.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'] as Map<String, dynamic>?;
    return CertificateTemplate(
      id: (json['id'] as num).toInt(),
      nama: json['nama'] as String? ?? '',
      deskripsi: json['deskripsi'] as String?,
      htmlContent: json['html_content'] as String? ?? '',
      orientation: json['orientation'] as String? ?? 'portrait',
      paperSize: json['paper_size'] as String? ?? 'a4',
      logoPath: json['logo_path'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      creatorName: creator?['name'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}

/// A certificate that has been issued to a student from a template.
class IssuedCertificate {
  final int id;
  final String nomorSertifikat;
  final int userId;
  final int templateId;
  final String? studentName;
  final String? studentAvatar;
  final String? templateNama;
  final String namaKursus;
  final DateTime? tanggalLulus;
  final DateTime? issuedAt;
  final String? issuerName;

  const IssuedCertificate({
    required this.id,
    required this.nomorSertifikat,
    required this.userId,
    required this.templateId,
    this.studentName,
    this.studentAvatar,
    this.templateNama,
    required this.namaKursus,
    this.tanggalLulus,
    this.issuedAt,
    this.issuerName,
  });

  factory IssuedCertificate.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>?;
    final template = json['template'] as Map<String, dynamic>?;
    final issuer = json['issuer'] as Map<String, dynamic>?;
    return IssuedCertificate(
      id: (json['id'] as num).toInt(),
      nomorSertifikat: json['nomor_sertifikat'] as String? ?? '',
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      templateId: (json['template_id'] as num?)?.toInt() ?? 0,
      studentName: student?['name'] as String?,
      studentAvatar: student?['avatar'] as String?,
      templateNama: template?['nama'] as String?,
      namaKursus: json['nama_kursus'] as String? ?? '',
      tanggalLulus:
          json['tanggal_lulus'] != null ? DateTime.tryParse(json['tanggal_lulus']) : null,
      issuedAt: json['issued_at'] != null ? DateTime.tryParse(json['issued_at']) : null,
      issuerName: issuer?['name'] as String?,
    );
  }
}

/// Minimal student option used when picking a recipient for a new
/// certificate (reuses admin user list shape loosely).
class StudentOption {
  final int id;
  final String name;
  final String username;
  final String? avatar;
  final String? cabangNama;

  const StudentOption({
    required this.id,
    required this.name,
    required this.username,
    this.avatar,
    this.cabangNama,
  });

  factory StudentOption.fromJson(Map<String, dynamic> json) {
    final cabang = json['cabang'] as Map<String, dynamic>?;
    return StudentOption(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatar: json['avatar'] as String?,
      cabangNama: cabang?['nama'] as String?,
    );
  }
}

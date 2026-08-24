/// A student attendance session: mentor logs a class meeting with a roster
/// of students and their status (hadir/izin/sakit/alpha).
class Presensi {
  final int id;
  final int kelasId;
  final String? kelasNama;
  final String tanggal;
  final String jamMulai;
  final String jamSelesai;
  final String materi;
  final String? foto;
  final int? studentsCount;
  final List<PresensiStudent> students;

  const Presensi({
    required this.id,
    required this.kelasId,
    this.kelasNama,
    required this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
    required this.materi,
    this.foto,
    this.studentsCount,
    this.students = const [],
  });

  factory Presensi.fromJson(Map<String, dynamic> json) {
    final kelasMaster = json['kelas_master'] as Map?;
    final studentsRaw = json['students'] as List?;
    return Presensi(
      id: (json['id'] as num).toInt(),
      kelasId: (json['kelas_id'] as num?)?.toInt() ?? 0,
      kelasNama: kelasMaster?['nama'] as String? ?? json['kelas'] as String?,
      tanggal: json['tanggal'] as String? ?? '',
      jamMulai: _trimTime(json['jam_mulai']),
      jamSelesai: _trimTime(json['jam_selesai']),
      materi: json['materi'] as String? ?? '',
      foto: json['foto'] as String?,
      studentsCount: (json['students_count'] as num?)?.toInt(),
      students: studentsRaw
              ?.map((s) => PresensiStudent.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  static String _trimTime(dynamic raw) {
    final s = raw as String? ?? '';
    return s.length >= 5 ? s.substring(0, 5) : s;
  }
}

class PresensiStudent {
  final int id;
  final String name;
  final String status; // hadir, izin, sakit, alpha

  const PresensiStudent({
    required this.id,
    required this.name,
    required this.status,
  });

  factory PresensiStudent.fromJson(Map<String, dynamic> json) {
    final pivot = json['pivot'] as Map?;
    return PresensiStudent(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      status: pivot?['status'] as String? ?? 'hadir',
    );
  }
}

/// Result row from GET /presensi/students/search — used to build the
/// roster when creating a new attendance session.
class StudentSearchResult {
  final int id;
  final String name;
  final String? kelas;
  final String? cabang;

  const StudentSearchResult({
    required this.id,
    required this.name,
    this.kelas,
    this.cabang,
  });

  factory StudentSearchResult.fromJson(Map<String, dynamic> json) => StudentSearchResult(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        kelas: json['kelas'] as String?,
        cabang: json['cabang'] as String?,
      );
}

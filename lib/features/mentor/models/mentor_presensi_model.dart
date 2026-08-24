/// Mentor's own daily attendance record (jam datang/pulang, jumlah murid).
/// Distinct from [Presensi] which is the mentor logging STUDENT attendance.
class MentorPresensi {
  final int id;
  final int kelasId;
  final String? kelasNama;
  final String tanggal;
  final String jamDatang;
  final String jamPulang;
  final int jumlahMurid;
  final String? catatan;

  const MentorPresensi({
    required this.id,
    required this.kelasId,
    this.kelasNama,
    required this.tanggal,
    required this.jamDatang,
    required this.jamPulang,
    required this.jumlahMurid,
    this.catatan,
  });

  factory MentorPresensi.fromJson(Map<String, dynamic> json) {
    final kelas = json['kelas'] as Map?;
    return MentorPresensi(
      id: (json['id'] as num).toInt(),
      kelasId: (json['kelas_id'] as num?)?.toInt() ?? 0,
      kelasNama: kelas?['nama'] as String?,
      tanggal: json['tanggal'] as String? ?? '',
      jamDatang: _trimTime(json['jam_datang']),
      jamPulang: _trimTime(json['jam_pulang']),
      jumlahMurid: (json['jumlah_murid'] as num?)?.toInt() ?? 0,
      catatan: json['catatan'] as String?,
    );
  }

  static String _trimTime(dynamic raw) {
    final s = raw as String? ?? '';
    // Backend may return "08:00:00" (H:i:s) — UI only needs H:i.
    return s.length >= 5 ? s.substring(0, 5) : s;
  }
}

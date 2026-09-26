/// One attendance session logged by a mentor (admin cross-branch view).
class MentorPresensiEntry {
  final int id;
  final int mentorId;
  final String? mentorName;
  final int? cabangId;
  final String? cabangNama;
  final int? kelasId;
  final String? kelasNama;
  final DateTime? tanggal;
  final String? jamDatang;
  final String? jamPulang;
  final int jumlahMurid;
  final String? catatan;

  const MentorPresensiEntry({
    required this.id,
    required this.mentorId,
    this.mentorName,
    this.cabangId,
    this.cabangNama,
    this.kelasId,
    this.kelasNama,
    this.tanggal,
    this.jamDatang,
    this.jamPulang,
    required this.jumlahMurid,
    this.catatan,
  });

  factory MentorPresensiEntry.fromJson(Map<String, dynamic> json) {
    final mentor = json['mentor'] as Map<String, dynamic>?;
    final cabang = json['cabang'] as Map<String, dynamic>?;
    final kelas = json['kelas'] as Map<String, dynamic>?;
    return MentorPresensiEntry(
      id: (json['id'] as num).toInt(),
      mentorId: (json['mentor_id'] as num?)?.toInt() ?? 0,
      mentorName: mentor?['name'] as String?,
      cabangId: (json['cabang_id'] as num?)?.toInt(),
      cabangNama: cabang?['nama'] as String?,
      kelasId: (json['kelas_id'] as num?)?.toInt(),
      kelasNama: kelas?['nama'] as String?,
      tanggal: json['tanggal'] != null ? DateTime.tryParse(json['tanggal']) : null,
      jamDatang: json['jam_datang'] as String?,
      jamPulang: json['jam_pulang'] as String?,
      jumlahMurid: (json['jumlah_murid'] as num?)?.toInt() ?? 0,
      catatan: json['catatan'] as String?,
    );
  }
}

/// Aggregated report totals returned by /admin/mentor-presensi/reports.
class MentorPresensiReportTotals {
  final int sesi;
  final double jam;
  final int murid;
  final int mentorAktif;

  const MentorPresensiReportTotals({
    required this.sesi,
    required this.jam,
    required this.murid,
    required this.mentorAktif,
  });

  factory MentorPresensiReportTotals.fromJson(Map<String, dynamic> json) {
    return MentorPresensiReportTotals(
      sesi: (json['sesi'] as num?)?.toInt() ?? 0,
      jam: (json['jam'] as num?)?.toDouble() ?? 0,
      murid: (json['murid'] as num?)?.toInt() ?? 0,
      mentorAktif: (json['mentor_aktif'] as num?)?.toInt() ?? 0,
    );
  }
}

class MentorPresensiPerMentor {
  final int mentorId;
  final String mentorName;
  final int sesi;
  final int muridTotal;
  final double muridAvg;

  const MentorPresensiPerMentor({
    required this.mentorId,
    required this.mentorName,
    required this.sesi,
    required this.muridTotal,
    required this.muridAvg,
  });

  factory MentorPresensiPerMentor.fromJson(Map<String, dynamic> json) {
    final mentor = json['mentor'] as Map<String, dynamic>?;
    return MentorPresensiPerMentor(
      mentorId: (json['mentor_id'] as num?)?.toInt() ?? 0,
      mentorName: mentor?['name'] as String? ?? '-',
      sesi: (json['sesi'] as num?)?.toInt() ?? 0,
      muridTotal: int.tryParse('${json['murid_total']}') ?? 0,
      muridAvg: double.tryParse('${json['murid_avg']}') ?? 0,
    );
  }
}

class MentorPresensiReport {
  final List<MentorPresensiPerMentor> perMentor;
  final List<MentorPresensiEntry> detail;
  final MentorPresensiReportTotals totals;
  final String from;
  final String to;

  const MentorPresensiReport({
    required this.perMentor,
    required this.detail,
    required this.totals,
    required this.from,
    required this.to,
  });

  factory MentorPresensiReport.fromJson(Map<String, dynamic> json) {
    final perMentorRaw = json['perMentor'] as List? ?? [];
    final detailRaw = json['detail'] as List? ?? [];
    return MentorPresensiReport(
      perMentor: perMentorRaw
          .map((e) => MentorPresensiPerMentor.fromJson(e as Map<String, dynamic>))
          .toList(),
      detail: detailRaw
          .map((e) => MentorPresensiEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      totals: MentorPresensiReportTotals.fromJson(
          json['totals'] as Map<String, dynamic>? ?? const {}),
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
    );
  }
}

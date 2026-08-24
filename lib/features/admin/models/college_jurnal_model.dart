// Model for Jurnal College admin features:
// - CollegeJurnalDashboard: summary/stats for college students jurnal
// - CollegeBibleItem: bible reading schedule items
// - CollegeItem: generic college curriculum items

class CollegeJurnalUser {
  final int id;
  final String name;
  final String email;
  final int? checksLastWeek;
  final bool activeToday;
  final double pctWeek;

  const CollegeJurnalUser({
    required this.id,
    required this.name,
    required this.email,
    this.checksLastWeek,
    this.activeToday = false,
    this.pctWeek = 0,
  });

  factory CollegeJurnalUser.fromJson(Map<String, dynamic> j) =>
      CollegeJurnalUser(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        checksLastWeek: j['checks_last_7_days'] as int?,
        activeToday: j['active_today'] == true,
        pctWeek: (j['pct_week'] as num?)?.toDouble() ?? 0,
      );
}

class CollegeBibleItem {
  final int id;
  final int dayNo;
  final String title;
  final String passage;
  final String? notes;

  const CollegeBibleItem({
    required this.id,
    required this.dayNo,
    required this.title,
    required this.passage,
    this.notes,
  });

  factory CollegeBibleItem.fromJson(Map<String, dynamic> j) =>
      CollegeBibleItem(
        id: (j['id'] as num).toInt(),
        dayNo: (j['day_no'] as num?)?.toInt() ?? 0,
        title: j['title'] as String? ?? '',
        passage: j['passage'] as String? ?? '',
        notes: j['notes'] as String?,
      );
}

class CollegeItem {
  final int id;
  final String name;
  final String? description;
  final bool isActive;

  const CollegeItem({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
  });

  factory CollegeItem.fromJson(Map<String, dynamic> j) => CollegeItem(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String? ?? j['judul'] as String? ?? '',
        description: j['description'] as String? ?? j['deskripsi'] as String?,
        isActive: j['is_active'] != false,
      );
}

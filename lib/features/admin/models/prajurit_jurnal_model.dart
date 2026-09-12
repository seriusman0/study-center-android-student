// Model for Jurnal prajurit admin features:
// - PrajuritJurnalDashboard: summary/stats for prajurit students jurnal
// - PrajuritBibleItem: bible reading schedule items
// - prajuritItem: generic prajurit curriculum items

class PrajuritJurnalUser {
  final int id;
  final String name;
  final String email;
  final int? checksLastWeek;
  final bool activeToday;
  final double pctWeek;

  const PrajuritJurnalUser({
    required this.id,
    required this.name,
    required this.email,
    this.checksLastWeek,
    this.activeToday = false,
    this.pctWeek = 0,
  });

  factory PrajuritJurnalUser.fromJson(Map<String, dynamic> j) =>
      PrajuritJurnalUser(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        checksLastWeek: j['checks_last_7_days'] as int?,
        activeToday: j['active_today'] == true,
        pctWeek: (j['pct_week'] as num?)?.toDouble() ?? 0,
      );
}

class PrajuritBibleItem {
  final int id;
  final int dayNo;
  final String title;
  final String passage;
  final String? notes;

  const PrajuritBibleItem({
    required this.id,
    required this.dayNo,
    required this.title,
    required this.passage,
    this.notes,
  });

  factory PrajuritBibleItem.fromJson(Map<String, dynamic> j) =>
      PrajuritBibleItem(
        id: (j['id'] as num).toInt(),
        dayNo: (j['day_no'] as num?)?.toInt() ?? 0,
        title: j['title'] as String? ?? '',
        passage: j['passage'] as String? ?? '',
        notes: j['notes'] as String?,
      );
}

class PrajuritItem {
  final int id;
  final String name;
  final String? description;
  final bool isActive;

  const PrajuritItem({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
  });

  factory PrajuritItem.fromJson(Map<String, dynamic> j) => PrajuritItem(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String? ?? j['judul'] as String? ?? '',
        description: j['description'] as String? ?? j['deskripsi'] as String?,
        isActive: j['is_active'] != false,
      );
}

class JurnalMonitorSummaryRole {
  final int totalUsers;
  final int activeToday;
  final int activeWeek;
  final double pctToday;
  final double pctWeek;

  const JurnalMonitorSummaryRole({
    required this.totalUsers,
    required this.activeToday,
    required this.activeWeek,
    required this.pctToday,
    required this.pctWeek,
  });

  factory JurnalMonitorSummaryRole.fromJson(Map<String, dynamic> json) =>
      JurnalMonitorSummaryRole(
        totalUsers: (json['total_users'] as num?)?.toInt() ?? 0,
        activeToday: (json['active_today'] as num?)?.toInt() ?? 0,
        activeWeek: (json['active_week'] as num?)?.toInt() ?? 0,
        pctToday: (json['pct_today'] as num?)?.toDouble() ?? 0,
        pctWeek: (json['pct_week'] as num?)?.toDouble() ?? 0,
      );
}

class JurnalMonitorSummary {
  final String today;
  final Map<String, JurnalMonitorSummaryRole> byRole;

  const JurnalMonitorSummary({required this.today, required this.byRole});

  factory JurnalMonitorSummary.fromJson(Map<String, dynamic> json) {
    final byRoleRaw = json['by_role'] as Map<String, dynamic>? ?? {};
    return JurnalMonitorSummary(
      today: json['today'] as String? ?? '',
      byRole: byRoleRaw.map(
        (k, v) => MapEntry(k, JurnalMonitorSummaryRole.fromJson(v as Map<String, dynamic>)),
      ),
    );
  }
}

/// One user row in the per-role monitor list, with jurnal fill status
/// attached directly by the backend (last_jurnal_date, checks_last_7_days).
class JurnalMonitorUser {
  final int id;
  final String name;
  final String username;
  final String? avatar;
  final String? cabangNama;
  final String? lastJurnalDate;
  final int checksLast7Days;

  const JurnalMonitorUser({
    required this.id,
    required this.name,
    required this.username,
    this.avatar,
    this.cabangNama,
    this.lastJurnalDate,
    required this.checksLast7Days,
  });

  factory JurnalMonitorUser.fromJson(Map<String, dynamic> json) {
    final cabangObj = json['cabang'] as Map?;
    return JurnalMonitorUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatar: json['avatar'] as String?,
      cabangNama: cabangObj?['nama'] as String?,
      lastJurnalDate: json['last_jurnal_date'] as String?,
      checksLast7Days: (json['checks_last_7_days'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Full checklist matrix for one user (dates x jurnal items) — used for
/// the drill-down detail screen when admin taps a user.
class JurnalMonitorMatrix {
  final List<String> headers;
  final List<List<String>> rows;
  final double pct;
  final int checked;
  final int total;

  const JurnalMonitorMatrix({
    required this.headers,
    required this.rows,
    required this.pct,
    required this.checked,
    required this.total,
  });

  factory JurnalMonitorMatrix.fromJson(Map<String, dynamic> json) {
    final headersRaw = json['headers'] as List? ?? [];
    final rowsRaw = json['rows'] as List? ?? [];
    return JurnalMonitorMatrix(
      headers: headersRaw.map((e) => e.toString()).toList(),
      rows: rowsRaw.map((r) => (r as List).map((e) => e.toString()).toList()).toList(),
      pct: (json['pct'] as num?)?.toDouble() ?? 0,
      checked: (json['checked'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class JurnalMonitorDetail {
  final String userName;
  final String role;
  final String from;
  final String to;
  final JurnalMonitorMatrix matrix;

  const JurnalMonitorDetail({
    required this.userName,
    required this.role,
    required this.from,
    required this.to,
    required this.matrix,
  });

  factory JurnalMonitorDetail.fromJson(Map<String, dynamic> json) {
    final userObj = json['user'] as Map<String, dynamic>? ?? {};
    return JurnalMonitorDetail(
      userName: userObj['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      matrix: JurnalMonitorMatrix.fromJson(json['matrix'] as Map<String, dynamic>? ?? {}),
    );
  }
}

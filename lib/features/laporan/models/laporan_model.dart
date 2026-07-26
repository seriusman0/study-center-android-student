class LaporanSummary {
  final String from;
  final String to;
  final double pct;
  final int checked;
  final int total;
  final int streak;

  const LaporanSummary({
    required this.from,
    required this.to,
    required this.pct,
    required this.checked,
    required this.total,
    required this.streak,
  });

  factory LaporanSummary.fromJson(Map<String, dynamic> j) => LaporanSummary(
        from:    j['from'] as String? ?? '',
        to:      j['to'] as String? ?? '',
        pct:     (j['pct'] as num?)?.toDouble() ?? 0.0,
        checked: (j['checked'] as num?)?.toInt() ?? 0,
        total:   (j['total'] as num?)?.toInt() ?? 0,
        streak:  (j['streak'] as num?)?.toInt() ?? 0,
      );
}

class LaporanMatrix {
  final String from;
  final String to;
  final List<String> headers;
  final List<List<String>> rows;
  final double pct;
  final int checked;
  final int total;

  const LaporanMatrix({
    required this.from,
    required this.to,
    required this.headers,
    required this.rows,
    required this.pct,
    required this.checked,
    required this.total,
  });

  factory LaporanMatrix.fromJson(Map<String, dynamic> j) => LaporanMatrix(
        from:    j['from'] as String? ?? '',
        to:      j['to'] as String? ?? '',
        headers: List<String>.from((j['headers'] as List? ?? [])),
        rows:    ((j['rows'] as List?) ?? [])
            .map((r) => List<String>.from(r as List))
            .toList(),
        pct:     (j['pct'] as num?)?.toDouble() ?? 0.0,
        checked: (j['checked'] as num?)?.toInt() ?? 0,
        total:   (j['total'] as num?)?.toInt() ?? 0,
      );
}

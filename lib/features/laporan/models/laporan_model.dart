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
        from:    j['from'] ?? '',
        to:      j['to'] ?? '',
        pct:     (j['pct'] as num).toDouble(),
        checked: j['checked'] as int,
        total:   j['total'] as int,
        streak:  j['streak'] as int,
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
        from:    j['from'] ?? '',
        to:      j['to'] ?? '',
        headers: List<String>.from(j['headers'] as List),
        rows:    (j['rows'] as List).map((r) => List<String>.from(r as List)).toList(),
        pct:     (j['pct'] as num).toDouble(),
        checked: j['checked'] as int,
        total:   j['total'] as int,
      );
}

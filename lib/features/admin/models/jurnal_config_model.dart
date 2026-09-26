/// Models for admin-managed jurnal configuration:
/// life items (habit checklist), bible reading schedules, and weekly verses.

class JurnalLifeItem {
  final int id;
  final String kategori;
  final String label;
  final bool isDefault;
  final bool isActive;

  const JurnalLifeItem({
    required this.id,
    required this.kategori,
    required this.label,
    required this.isDefault,
    required this.isActive,
  });

  factory JurnalLifeItem.fromJson(Map<String, dynamic> json) {
    return JurnalLifeItem(
      id: (json['id'] as num).toInt(),
      kategori: json['kategori'] as String? ?? '',
      label: json['label'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'kategori': kategori,
        'label': label,
        'is_default': isDefault,
        'is_active': isActive,
      };
}

class JurnalBibleSchedule {
  final int id;
  final DateTime tanggal;
  final String? plPorsi;
  final String? pbPorsi;

  const JurnalBibleSchedule({
    required this.id,
    required this.tanggal,
    this.plPorsi,
    this.pbPorsi,
  });

  factory JurnalBibleSchedule.fromJson(Map<String, dynamic> json) {
    return JurnalBibleSchedule(
      id: (json['id'] as num).toInt(),
      tanggal: DateTime.parse(json['tanggal'] as String),
      plPorsi: json['pl_porsi'] as String?,
      pbPorsi: json['pb_porsi'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'tanggal':
            '${tanggal.year.toString().padLeft(4, '0')}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}',
        'pl_porsi': plPorsi,
        'pb_porsi': pbPorsi,
      };
}

class JurnalWeeklyVerse {
  final int id;
  final int tahun;
  final int bulan;
  final int minggu;
  final String referensi;
  final String isi;

  const JurnalWeeklyVerse({
    required this.id,
    required this.tahun,
    required this.bulan,
    required this.minggu,
    required this.referensi,
    required this.isi,
  });

  factory JurnalWeeklyVerse.fromJson(Map<String, dynamic> json) {
    return JurnalWeeklyVerse(
      id: (json['id'] as num).toInt(),
      tahun: (json['tahun'] as num).toInt(),
      bulan: (json['bulan'] as num).toInt(),
      minggu: (json['minggu'] as num).toInt(),
      referensi: json['referensi'] as String? ?? '',
      isi: json['isi'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'tahun': tahun,
        'bulan': bulan,
        'minggu': minggu,
        'referensi': referensi,
        'isi': isi,
      };
}

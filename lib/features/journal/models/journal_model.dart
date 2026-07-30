class BibleReading {
  final String plPorsi;
  final String pbPorsi;
  final bool plChecked;
  final bool pbChecked;
  final int? dayNo;
  final String? plText;
  final String? pbText;

  const BibleReading({
    required this.plPorsi,
    required this.pbPorsi,
    required this.plChecked,
    required this.pbChecked,
    this.dayNo,
    this.plText,
    this.pbText,
  });

  factory BibleReading.fromJson(
    Map<String, dynamic> j, {
    int? dayNo,
    Map<String, dynamic>? collegeBible,
  }) =>
      BibleReading(
        plPorsi:   j['pl_porsi'] ?? '',
        pbPorsi:   j['pb_porsi'] ?? '',
        plChecked: j['pl_checked'] == true,
        pbChecked: j['pb_checked'] == true,
        dayNo:     dayNo,
        plText:    collegeBible?['pl_text'] as String?,
        pbText:    collegeBible?['pb_text'] as String?,
      );

  BibleReading copyWith({bool? plChecked, bool? pbChecked}) => BibleReading(
        plPorsi:   plPorsi,
        pbPorsi:   pbPorsi,
        plChecked: plChecked ?? this.plChecked,
        pbChecked: pbChecked ?? this.pbChecked,
        dayNo:     dayNo,
        plText:    plText,
        pbText:    pbText,
      );

  String get collegePorsiHint {
    final parts = [if (plText?.isNotEmpty == true) plText!, if (pbText?.isNotEmpty == true) pbText!];
    return parts.isNotEmpty ? parts.join(' / ') : '';
  }
}

class LifeItem {
  final int id;
  final String kategori;
  final String label;
  final bool checked;

  const LifeItem({
    required this.id,
    required this.kategori,
    required this.label,
    required this.checked,
  });

  factory LifeItem.fromJson(Map<String, dynamic> j) => LifeItem(
        id:       j['id'] as int,
        kategori: j['kategori'] ?? '',
        label:    j['label'] ?? '',
        checked:  j['checked'] == true,
      );

  LifeItem copyWith({bool? checked}) => LifeItem(
        id: id,
        kategori: kategori,
        label: label,
        checked: checked ?? this.checked,
      );
}

const _kategoriLabel = {
  'kerohanian': 'Kerohanian',
  'pendidikan': 'Pendidikan',
  'karakter':   'Karakter',
};

const _kategoriOrder = ['kerohanian', 'pendidikan', 'karakter'];

class JournalSnapshot {
  final String date;
  final BibleReading bible;
  final String? verseRef;
  final String? photoUrl;
  final List<LifeItem> lifeItems;

  const JournalSnapshot({
    required this.date,
    required this.bible,
    this.verseRef,
    this.photoUrl,
    required this.lifeItems,
  });

  factory JournalSnapshot.fromJson(Map<String, dynamic> j) => JournalSnapshot(
        date:      j['date'] ?? '',
        bible:     BibleReading.fromJson(
          j['bible'] as Map<String, dynamic>,
          dayNo: j['day_no'] as int?,
          collegeBible: j['college_bible'] as Map<String, dynamic>?,
        ),
        verseRef:  j['verse_ref'] as String?,
        photoUrl:  _parsePhotoUrl(j),
        lifeItems: (j['life_items'] as List? ?? []).map((e) => LifeItem.fromJson(e)).toList(),
      );

  static String? _parsePhotoUrl(Map<String, dynamic> j) {
    final path = j['foto_belajar_url'] ?? j['foto_belajar'] ?? j['photo_url'] ?? j['foto_url'] ?? j['foto'] as String?;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return 'https://studycenter.nanoprojectdevindonesia.com/storage/$path';
  }

  int get checkedCount {
    int c = 0;
    if (bible.plChecked) c++;
    if (bible.pbChecked) c++;
    if (verseRef != null && verseRef!.isNotEmpty) c++;
    if (photoUrl != null && photoUrl!.isNotEmpty) c++;
    c += lifeItems.where((i) => i.checked && i.label != 'Baca Alkitab' && i.label != 'Hafal Ayat').length;
    return c;
  }

  int get totalCount => 4 + lifeItems.where((i) => i.label != 'Baca Alkitab' && i.label != 'Hafal Ayat').length;

  Map<String, List<LifeItem>> get lifeItemsByKategori {
    final map = <String, List<LifeItem>>{};
    for (final item in lifeItems) {
      map.putIfAbsent(item.kategori, () => []).add(item);
    }
    final ordered = <String, List<LifeItem>>{};
    for (final k in _kategoriOrder) {
      if (map.containsKey(k)) ordered[k] = map[k]!;
    }
    for (final k in map.keys) {
      if (!ordered.containsKey(k)) ordered[k] = map[k]!;
    }
    return ordered;
  }

  static String kategoriDisplayName(String k) => _kategoriLabel[k] ?? k;
}

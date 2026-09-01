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
        plPorsi: j['pl_porsi']?.toString() ?? '',
        pbPorsi: j['pb_porsi']?.toString() ?? '',
        plChecked: j['pl_checked'] == true ||
            j['pl_checked'] == 1 ||
            j['pl_checked'] == '1',
        pbChecked: j['pb_checked'] == true ||
            j['pb_checked'] == 1 ||
            j['pb_checked'] == '1',
        dayNo: dayNo,
        plText: collegeBible?['pl_text']?.toString(),
        pbText: collegeBible?['pb_text']?.toString(),
      );

  BibleReading copyWith({bool? plChecked, bool? pbChecked}) => BibleReading(
        plPorsi: plPorsi,
        pbPorsi: pbPorsi,
        plChecked: plChecked ?? this.plChecked,
        pbChecked: pbChecked ?? this.pbChecked,
        dayNo: dayNo,
        plText: plText,
        pbText: pbText,
      );

  String get collegePorsiHint {
    final parts = [
      if (plText?.isNotEmpty == true) plText!,
      if (pbText?.isNotEmpty == true) pbText!
    ];
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
        id: int.tryParse(j['id']?.toString() ?? '0') ?? 0,
        kategori: j['kategori']?.toString() ?? '',
        label: j['label']?.toString() ?? '',
        checked:
            j['checked'] == true || j['checked'] == 1 || j['checked'] == '1',
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
  'karakter': 'Karakter',
};

const _kategoriOrder = ['kerohanian', 'pendidikan', 'karakter'];

class JournalSnapshot {
  final String date;
  final BibleReading bible;
  final String? verseRef;

  /// Per-hari: apakah hafalan sudah dicentang hari ini.
  final bool verseChecked;
  final String? photoUrl;
  final List<LifeItem> lifeItems;

  const JournalSnapshot({
    required this.date,
    required this.bible,
    this.verseRef,
    this.verseChecked = false,
    this.photoUrl,
    required this.lifeItems,
  });

  factory JournalSnapshot.fromJson(Map<String, dynamic> j) {
    final rawLifeItems = j['life_items'];
    final lifeItemsList = rawLifeItems is List
        ? rawLifeItems
        : (rawLifeItems is Map ? rawLifeItems.values : []);

    final parsedItems = lifeItemsList
        .where((e) => e is Map)
        .map((e) => LifeItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    Map<String, dynamic> bibleMap = {};
    if (j['bible'] is Map) {
      bibleMap = Map<String, dynamic>.from(j['bible']);
    }

    final verseChecked = j['verse_checked'] == true ||
        j['verse_checked'] == 1 ||
        j['verse_checked'] == '1';

    return JournalSnapshot(
      date: j['date'] ?? '',
      bible: BibleReading.fromJson(
        bibleMap,
        dayNo: int.tryParse(j['day_no']?.toString() ?? '') ??
            int.tryParse(bibleMap['day_no']?.toString() ?? ''),
        collegeBible: j['college_bible'] is Map
            ? Map<String, dynamic>.from(j['college_bible'])
            : null,
      ),
      verseRef: j['verse_ref']?.toString(),
      verseChecked: verseChecked,
      photoUrl: _parsePhotoUrl(j),
      lifeItems: parsedItems,
    );
  }

  static String? _parsePhotoUrl(Map<String, dynamic> j) {
    final pathVal = j['foto_belajar_url'] ??
        j['foto_belajar'] ??
        j['photo_url'] ??
        j['foto_url'] ??
        j['foto'];
    final path = pathVal?.toString();
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return 'https://studycenter.nanoprojectdevindonesia.com/storage/$path';
  }

  JournalSnapshot copyWith({
    String? date,
    BibleReading? bible,
    String? verseRef,
    bool? verseChecked,
    String? photoUrl,
    List<LifeItem>? lifeItems,
    // Sentinel to allow clearing verseRef to null explicitly.
    bool clearVerseRef = false,
    bool clearPhotoUrl = false,
  }) {
    return JournalSnapshot(
      date: date ?? this.date,
      bible: bible ?? this.bible,
      verseRef: clearVerseRef ? null : (verseRef ?? this.verseRef),
      verseChecked: verseChecked ?? this.verseChecked,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      lifeItems: lifeItems ?? this.lifeItems,
    );
  }

  /// Jumlah item yang sudah dicentang/diselesaikan.
  /// verse_checked (bukan verseRef) dipakai untuk menghitung centang hafalan.
  int get checkedCount {
    int c = 0;
    if (bible.plChecked) c++;
    if (bible.pbChecked) c++;
    if (verseChecked) c++;
    if (photoUrl != null && photoUrl!.isNotEmpty) c++;
    c += lifeItems.where((i) => i.checked).length;
    return c;
  }

  int get totalCount => 4 + lifeItems.length;

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

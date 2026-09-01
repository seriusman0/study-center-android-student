class CollegeBible {
  final int dayNo;
  final String plText;
  final String pbText;
  final bool plChecked;
  final bool pbChecked;

  const CollegeBible({
    required this.dayNo,
    required this.plText,
    required this.pbText,
    required this.plChecked,
    required this.pbChecked,
  });

  factory CollegeBible.fromJson(Map<String, dynamic> j) => CollegeBible(
        dayNo:     j['day_no'] as int? ?? 0,
        plText:    j['pl_porsi'] ?? j['pl_text'] ?? '',
        pbText:    j['pb_porsi'] ?? j['pb_text'] ?? '',
        plChecked: j['pl_checked'] == true,
        pbChecked: j['pb_checked'] == true,
      );

  CollegeBible copyWith({bool? plChecked, bool? pbChecked}) => CollegeBible(
        dayNo:     dayNo,
        plText:    plText,
        pbText:    pbText,
        plChecked: plChecked ?? this.plChecked,
        pbChecked: pbChecked ?? this.pbChecked,
      );
}

/// response_type: 'check' (toggle), 'boolean' (Sudah/Belum), 'time_range' (study log)
enum CollegeItemResponseType { check, boolean, timeRange, unknown }

class CollegeLifeItem {
  final int id;
  final String kategori;
  final String label;
  final CollegeItemResponseType responseType;
  final bool checked;

  const CollegeLifeItem({
    required this.id,
    required this.kategori,
    required this.label,
    required this.responseType,
    required this.checked,
  });

  factory CollegeLifeItem.fromJson(Map<String, dynamic> j) => CollegeLifeItem(
        id:            j['id'] as int,
        kategori:      j['kategori'] ?? '',
        label:         j['label'] ?? '',
        responseType:  _parseResponseType(j['response_type']),
        checked:       j['checked'] == true,
      );

  static CollegeItemResponseType _parseResponseType(dynamic v) {
    switch (v) {
      case 'check':       return CollegeItemResponseType.check;
      case 'boolean':     return CollegeItemResponseType.boolean;
      case 'time_range':  return CollegeItemResponseType.timeRange;
      default:            return CollegeItemResponseType.unknown;
    }
  }

  String get responseTypeStr => switch (responseType) {
        CollegeItemResponseType.check => 'check',
        CollegeItemResponseType.boolean => 'boolean',
        CollegeItemResponseType.timeRange => 'time_range',
        _ => 'check',
      };

  CollegeLifeItem copyWith({bool? checked}) => CollegeLifeItem(
        id:             id,
        kategori:       kategori,
        label:          label,
        responseType:   responseType,
        checked:        checked ?? this.checked,
      );
}

/// Jam belajar: jam_mulai, jam_selesai, tipe (mandiri/kelompok)
class StudyLog {
  final int itemId;
  final String jamMulai;
  final String jamSelesai;
  final String tipe;
  final int totalMinutes;

  const StudyLog({
    required this.itemId,
    required this.jamMulai,
    required this.jamSelesai,
    required this.tipe,
    this.totalMinutes = 0,
  });

  factory StudyLog.fromJson(Map<String, dynamic> j) {
    final jm = j['jam_mulai'] ?? '00:00';
    final js = j['jam_selesai'] ?? '00:00';
    return StudyLog(
      itemId:    j['item_id'] as int? ?? j['life_item_id'] as int? ?? 0,
      jamMulai:  jm,
      jamSelesai: js,
      tipe:      j['tipe'] ?? 'mandiri',
    );
  }

  StudyLog copyWith({String? jamMulai, String? jamSelesai, String? tipe}) => StudyLog(
        itemId:      itemId,
        jamMulai:    jamMulai ?? this.jamMulai,
        jamSelesai:  jamSelesai ?? this.jamSelesai,
        tipe:        tipe ?? this.tipe,
        totalMinutes: _calcMinutes(jamMulai ?? this.jamMulai, jamSelesai ?? this.jamSelesai),
      );

  static int _calcMinutes(String start, String end) {
    try {
      final s = start.split(':');
      final e = end.split(':');
      if (s.length != 2 || e.length != 2) return 0;
      final sh = int.parse(s[0]), sm = int.parse(s[1]);
      final eh = int.parse(e[0]), em = int.parse(e[1]);
      int mins = (eh * 60 + em) - (sh * 60 + sm);
      if (mins < 0) mins += 1440; // crosses midnight
      return mins;
    } catch (_) {
      return 0;
    }
  }
}

/// College form window config
class CollegeFormConfig {
  final String formOpenTime;
  final String formCloseTime;
  final bool formActive;

  const CollegeFormConfig({
    required this.formOpenTime,
    required this.formCloseTime,
    required this.formActive,
  });

  factory CollegeFormConfig.fromJson(Map<String, dynamic> j) => CollegeFormConfig(
        formOpenTime:  j['form_open_time'] ?? '',
        formCloseTime: j['form_close_time'] ?? '',
        formActive:    j['form_active'] == true,
      );
}

/// Week metadata
class CollegeWeekMeta {
  final int tahun;
  final int bulan;
  final int minggu;
  final String key;

  const CollegeWeekMeta({
    required this.tahun,
    required this.bulan,
    required this.minggu,
    required this.key,
  });

  factory CollegeWeekMeta.fromJson(Map<String, dynamic> j) => CollegeWeekMeta(
        tahun: j['tahun'] as int? ?? 0,
        bulan: j['bulan'] as int? ?? 0,
        minggu: j['minggu'] as int? ?? 0,
        key:   j['key'] as String? ?? '',
      );
}

/// College journal snapshot — mirrors backend CollegeJurnalApiController::snapshot()
class CollegeJournalSnapshot {
  final String date;
  final CollegeWeekMeta? week;
  final CollegeFormConfig config;
  final CollegeBible bible;
  final List<CollegeLifeItem> lifeItems;
  final Map<int, StudyLog> studyLogs;
  final String? verseRef;
  final bool verseChecked;
  final String? fotoBelajarUrl;
  final int streak;

  const CollegeJournalSnapshot({
    required this.date,
    this.week,
    required this.config,
    required this.bible,
    required this.lifeItems,
    required this.studyLogs,
    this.verseRef,
    this.verseChecked = false,
    this.fotoBelajarUrl,
    this.streak = 0,
  });

  factory CollegeJournalSnapshot.fromJson(Map<String, dynamic> j) {
    final itemsList = (j['life_items'] as List? ?? []);
    final lifeItems = itemsList.map((e) =>
      CollegeLifeItem.fromJson(e as Map<String, dynamic>)
    ).toList();

    // Backend may return study_logs as either a Map {item_id: {...}}
    // (student endpoint) or a List [...] (college endpoint). Handle both.
    final studyLogsRaw = j['study_logs'];
    final Map<String, dynamic> studyLogsMap = switch (studyLogsRaw) {
      Map<String, dynamic> m => m,
      List l => {},
      _ => {},
    };
    final studyLogs = <int, StudyLog>{};
    for (final item in lifeItems) {
      final logData = studyLogsMap[item.id.toString()];
      if (logData != null) {
        studyLogs[item.id] = StudyLog.fromJson(Map<String, dynamic>.from(logData));
      }
    }

    return CollegeJournalSnapshot(
      date:            j['date'] ?? '',
      week:            j['week'] != null ? CollegeWeekMeta.fromJson(j['week']) : null,
      config:          CollegeFormConfig.fromJson(j['config'] is Map ? Map<String, dynamic>.from(j['config']) : {}),
      bible:           CollegeBible.fromJson(j['bible'] is Map ? Map<String, dynamic>.from(j['bible']) : {}),
      lifeItems:       lifeItems,
      studyLogs:       studyLogs,
      verseRef:        j['verse_ref'] as String?,
      verseChecked:    j['verse_checked'] == true || j['verse_checked'] == 1 || j['verse_checked'] == '1',
      fotoBelajarUrl:  _parseFotoUrl(j),
      streak:          j['streak'] as int? ?? 0,
    );
  }

  static String? _parseFotoUrl(Map<String, dynamic> j) {
    final path = j['foto_belajar_url'] ?? j['photo_url'] ?? j['foto_url'] ?? j['foto'] as String?;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return 'https://studycenter.nanoprojectdevindonesia.com/storage/$path';
  }

  int get checkedCount {
    int c = 0;
    if (bible.plChecked) c++;
    if (bible.pbChecked) c++;
    if (verseChecked) c++;
    c += lifeItems.where((i) => i.checked).length;
    return c;
  }

  int get totalCount => 2 + (verseRef != null ? 1 : 0) + lifeItems.length;

  Map<String, List<CollegeLifeItem>> get lifeItemsByKategori {
    final map = <String, List<CollegeLifeItem>>{};
    for (final item in lifeItems) {
      map.putIfAbsent(item.kategori, () => []).add(item);
    }
    // Fixed order: pembacaan, sidang, rohani
    const order = ['pembacaan', 'sidang', 'rohani'];
    final ordered = <String, List<CollegeLifeItem>>{};
    for (final k in order) {
      if (map.containsKey(k)) ordered[k] = map[k]!;
    }
    for (final k in map.keys) {
      if (!ordered.containsKey(k)) ordered[k] = map[k]!;
    }
    return ordered;
  }

  static String kategoriDisplayName(String k) {
    switch (k) {
      case 'pembacaan': return 'PEMBUACAAN';
      case 'sidang':    return 'SIDANG-SIDANG GEREJA';
      case 'rohani':    return 'KEGALANGAN ROHANI';
      default:          return k.toUpperCase();
    }
  }

  CollegeJournalSnapshot copyWith({
    bool? biblePlChecked,
    bool? biblePbChecked,
    List<CollegeLifeItem>? lifeItems,
    Map<int, StudyLog>? studyLogs,
    String? verseRef,
    bool? verseChecked,
    String? fotoBelajarUrl,
    bool clearVerseRef = false,
  }) => CollegeJournalSnapshot(
        date:            date,
        week:            week,
        config:            config,
        bible:            bible.copyWith(
          plChecked: biblePlChecked ?? bible.plChecked,
          pbChecked: biblePbChecked ?? bible.pbChecked,
        ),
        lifeItems:         lifeItems ?? this.lifeItems,
        studyLogs:         studyLogs ?? this.studyLogs,
        verseRef:          clearVerseRef ? null : (verseRef ?? this.verseRef),
        verseChecked:      verseChecked ?? this.verseChecked,
        fotoBelajarUrl:    fotoBelajarUrl ?? this.fotoBelajarUrl,
        streak:            streak,
    );
}

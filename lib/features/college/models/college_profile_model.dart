import '../models/college_journal_model.dart';

// CollegeProfile (simple data class)
class CollegeProfile {
  final String? institutionName;
  final String? position;

  const CollegeProfile({this.institutionName, this.position});

  factory CollegeProfile.fromJson(Map<String, dynamic> j) => CollegeProfile(
        institutionName: j['institution_name'] as String?,
        position:        j['position'] as String?,
      );
}

// History entry (one day)
class CollegeJournalHistoryDay {
  final String date;
  final bool plChecked;
  final bool pbChecked;
  final List<int> lifeCheckedIds;
  final List<StudyLog> studyLogs;

  const CollegeJournalHistoryDay({
    required this.date,
    required this.plChecked,
    required this.pbChecked,
    required this.lifeCheckedIds,
    required this.studyLogs,
  });

  factory CollegeJournalHistoryDay.fromJson(Map<String, dynamic> j) => CollegeJournalHistoryDay(
        date:            j['date'] ?? '',
        plChecked:       j['pl_checked'] == true,
        pbChecked:       j['pb_checked'] == true,
        lifeCheckedIds:  (j['life_checked_ids'] as List? ?? []).map((e) => e as int).toList(),
        studyLogs:       (j['study_logs'] as List? ?? []).map((e) => StudyLog.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class CollegeJournalHistory {
  final List<CollegeJournalHistoryDay> days;

  const CollegeJournalHistory({required this.days});

  factory CollegeJournalHistory.fromJson(List<dynamic> list) => CollegeJournalHistory(
        days: list.map((e) => CollegeJournalHistoryDay.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

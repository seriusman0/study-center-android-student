class ScholarshipJournalSummary {
  final int id;
  final String title;
  final String studentName;
  final String? campus;
  final int periodMonth;
  final int periodYear;
  final String status;
  final String statusLabel;
  final String? submittedAt;

  const ScholarshipJournalSummary({
    required this.id,
    required this.title,
    required this.studentName,
    required this.campus,
    required this.periodMonth,
    required this.periodYear,
    required this.status,
    required this.statusLabel,
    this.submittedAt,
  });

  factory ScholarshipJournalSummary.fromJson(Map<String, dynamic> j) => ScholarshipJournalSummary(
        id:             j['id'] as int,
        title:          j['title'] ?? '',
        studentName:    j['student'] ?? '',
        campus:         j['campus'] as String?,
        periodMonth:    (j['period_month'] as int? ?? 0),
        periodYear:     (j['period_year'] as int? ?? 0),
        status:         j['status'] ?? 'draft',
        statusLabel:    j['status_label'] ?? j['status'],
        submittedAt:    j['submitted_at'] as String?,
      );
}

class ScholarshipJournalItem {
  final double? gpaCurrentSemester;
  final double? cumulativeGpa;
  final double? classAttendancePercentage;
  final String? academicSummary;
  final String? organizationActivities;
  final String? trainingSeminars;
  final String? achievements;
  final String? communityServiceDetails;
  final int? serviceHours;
  final String? personalReflection;
  final String? nextMonthGoals;

  const ScholarshipJournalItem({
    this.gpaCurrentSemester,
    this.cumulativeGpa,
    this.classAttendancePercentage,
    this.academicSummary,
    this.organizationActivities,
    this.trainingSeminars,
    this.achievements,
    this.communityServiceDetails,
    this.serviceHours,
    this.personalReflection,
    this.nextMonthGoals,
  });

  factory ScholarshipJournalItem.fromJson(Map<String, dynamic> j) => ScholarshipJournalItem(
        gpaCurrentSemester:        (j['gpa_current_semester'] as num?)?.toDouble(),
        cumulativeGpa:             (j['cumulative_gpa'] as num?)?.toDouble(),
        classAttendancePercentage: (j['class_attendance_percentage'] as num?)?.toDouble(),
        academicSummary:           j['academic_summary'] as String?,
        organizationActivities:    j['organization_activities'] as String?,
        trainingSeminars:          j['training_seminars'] as String?,
        achievements:              j['achievements'] as String?,
        communityServiceDetails:   j['community_service_details'] as String?,
        serviceHours:              j['service_hours'] as int?,
        personalReflection:        j['personal_reflection'] as String?,
        nextMonthGoals:            j['next_month_goals'] as String?,
      );
}

class JournalStudent {
  final int id;
  final String name;
  final String? avatar;
  final String? campus;
  final int? semester;

  const JournalStudent({
    required this.id,
    required this.name,
    this.avatar,
    this.campus,
    this.semester,
  });

  factory JournalStudent.fromJson(Map<String, dynamic> j) => JournalStudent(
        id:      j['id'] as int,
        name:    j['name'] ?? '',
        avatar:  j['avatar'] as String?,
        campus:  j['campus'] as String?,
        semester: (j['semester'] as int?),
      );
}

class JournalAttachment {
  final int id;
  final String url;
  final String name;

  const JournalAttachment({
    required this.id,
    required this.url,
    required this.name,
  });

  factory JournalAttachment.fromJson(Map<String, dynamic> j) => JournalAttachment(
        id:   j['id'] as int,
        url:  j['url'] ?? '',
        name: j['name'] ?? '',
      );
}

class JournalReviewer {
  final int id;
  final String name;

  const JournalReviewer({required this.id, required this.name});

  factory JournalReviewer.fromJson(Map<String, dynamic> j) => JournalReviewer(
        id:   j['id'] as int,
        name: j['name'] ?? '',
      );
}

class ScholarshipJournalDetail {
  final int id;
  final String title;
  final int periodMonth;
  final int periodYear;
  final String status;
  final String statusLabel;
  final String? submittedAt;
  final String? reviewerNotes;
  final JournalStudent student;
  final ScholarshipJournalItem? item;
  final List<JournalAttachment> attachments;
  final JournalReviewer? reviewer;
  final bool canReview;

  const ScholarshipJournalDetail({
    required this.id,
    required this.title,
    required this.periodMonth,
    required this.periodYear,
    required this.status,
    required this.statusLabel,
    this.submittedAt,
    this.reviewerNotes,
    required this.student,
    this.item,
    required this.attachments,
    this.reviewer,
    required this.canReview,
  });

  factory ScholarshipJournalDetail.fromJson(Map<String, dynamic> j) => ScholarshipJournalDetail(
        id:             j['id'] as int,
        title:          j['title'] ?? '',
        periodMonth:    (j['period_month'] as int? ?? 0),
        periodYear:     (j['period_year'] as int? ?? 0),
        status:         j['status'] ?? 'draft',
        statusLabel:    j['status_label'] ?? j['status'],
        submittedAt:    j['submitted_at'] as String?,
        reviewerNotes:  j['reviewer_notes'] as String?,
        student:        JournalStudent.fromJson(j['student'] as Map<String, dynamic>),
        item:           j['item'] != null ? ScholarshipJournalItem.fromJson(j['item'] as Map<String, dynamic>) : null,
        attachments:    (j['attachments'] as List? ?? []).map((e) => JournalAttachment.fromJson(e as Map<String, dynamic>)).toList(),
        reviewer:       j['reviewer'] != null ? JournalReviewer.fromJson(j['reviewer'] as Map<String, dynamic>) : null,
        canReview:      j['can_review'] == true,
      );
}

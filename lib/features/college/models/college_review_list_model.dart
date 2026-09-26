import 'college_review_model.dart';

class CollegeReviewList {
  final List<ScholarshipJournalSummary> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const CollegeReviewList({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory CollegeReviewList.fromJson(Map<String, dynamic> j) {
    final meta = j['meta'] as Map? ?? {};
    return CollegeReviewList(
      items:       (j['data'] as List? ?? []).map((e) => ScholarshipJournalSummary.fromJson(e as Map<String, dynamic>)).toList(),
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage:    meta['last_page'] as int? ?? 1,
      perPage:     meta['per_page'] as int? ?? 20,
      total:       meta['total'] as int? ?? 0,
    );
  }
}

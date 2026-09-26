import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/college_review_model.dart';
import '../models/college_review_list_model.dart';
import '../repositories/college_repository.dart';

class CollegeReviewState {
  final List<ScholarshipJournalSummary> journals;
  final bool loading;
  final String? error;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? filterStatus;
  final String? filterCampus;
  final String? filterQ;

  CollegeReviewState({
    this.journals = const [],
    this.loading = false,
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.filterStatus,
    this.filterCampus,
    this.filterQ,
  });

  CollegeReviewState copyWith({
    List<ScholarshipJournalSummary>? journals,
    bool? loading,
    String? error,
    int? currentPage,
    int? lastPage,
    int? total,
    String? filterStatus,
    String? filterCampus,
    String? filterQ,
  }) => CollegeReviewState(
          journals: journals ?? this.journals,
          loading: loading ?? this.loading,
          error: error,
          currentPage: currentPage ?? this.currentPage,
          lastPage: lastPage ?? this.lastPage,
          total: total ?? this.total,
          filterStatus: filterStatus ?? this.filterStatus,
          filterCampus: filterCampus ?? this.filterCampus,
          filterQ: filterQ ?? this.filterQ,
        );
}

class CollegeReviewNotifier extends Notifier<CollegeReviewState> {
  @override
  CollegeReviewState build() {
    return CollegeReviewState();
  }

  Future<void> load({bool refresh = true, int? page}) async {
    final targetPage = page ?? (refresh ? 1 : state.currentPage + 1);
    if (targetPage > state.lastPage && !refresh) return;

    state = state.copyWith(loading: true, error: null, currentPage: targetPage);

    try {
      final list = await ref.read(collegeReviewRepositoryProvider).list(
            status: state.filterStatus,
            q: state.filterQ,
            campus: state.filterCampus,
            page: targetPage,
            perPage: 20,
          );

      final combined = refresh ? list.items : [...state.journals, ...list.items];
      state = state.copyWith(
        journals: combined,
        loading: false,
        currentPage: list.currentPage,
        lastPage: list.lastPage,
        total: list.total,
      );
    } catch (e) {
      debugPrint('[CollegeReview] load() error: $e');
      state = state.copyWith(
        loading: false,
        error: e.toString(),
        currentPage: targetPage,
      );
    }
  }

  Future<void> setFilters({String? status, String? campus, String? q}) async {
    state = state.copyWith(
      filterStatus: status,
      filterCampus: campus,
      filterQ: q,
    );
    await load(refresh: true);
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      filterStatus: null,
      filterCampus: null,
      filterQ: null,
    );
    await load(refresh: true);
  }

  Future<bool> submitReview(int id, {required String action, String? notes}) async {
    try {
      await ref.read(collegeReviewRepositoryProvider).submitReview(
            id,
            action: action,
            notes: notes,
          );
      // Remove from list if it was pending review
      final updated = state.journals.where((j) => j.id != id).toList();
      state = state.copyWith(journals: updated);
      return true;
    } catch (e) {
      debugPrint('[CollegeReview] submitReview error: $e');
      rethrow;
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.currentPage >= state.lastPage) return;
    await load(refresh: false);
  }
}

final collegeReviewProvider =
    NotifierProvider<CollegeReviewNotifier, CollegeReviewState>(CollegeReviewNotifier.new);

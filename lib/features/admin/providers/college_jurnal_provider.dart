import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/college_jurnal_model.dart';

// ── Repository ─────────────────────────────────────────────────────────────

class CollegeJurnalRepository {
  final Dio _dio;
  const CollegeJurnalRepository(this._dio);

  Future<List<CollegeJurnalUser>> fetchDashboard() async {
    final r = await _dio.get(ApiConstants.adminJurnalCollegeDashboard);
    final data = r.data;
    // Response may be {users: [...]} or directly a list
    List raw = data is Map ? (data['users'] ?? data['data'] ?? []) : data as List;
    return raw.map((e) => CollegeJurnalUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CollegeBibleItem>> fetchBibleItems() async {
    final r = await _dio.get(ApiConstants.adminJurnalCollegeBible);
    final raw = (r.data as List?) ?? [];
    return raw.map((e) => CollegeBibleItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CollegeItem>> fetchCollegeItems() async {
    final r = await _dio.get(ApiConstants.adminJurnalCollegeItems);
    final data = r.data;
    List raw = data is Map ? (data['data'] ?? []) : data as List;
    return raw.map((e) => CollegeItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final collegeJurnalRepoProvider = Provider(
  (ref) => CollegeJurnalRepository(ref.read(dioProvider)),
);

// ── Dashboard state ────────────────────────────────────────────────────────

class CollegeDashboardState {
  final bool loading;
  final List<CollegeJurnalUser> users;
  final String? error;
  const CollegeDashboardState({this.loading = false, this.users = const [], this.error});
}

class CollegeDashboardNotifier extends Notifier<CollegeDashboardState> {
  @override
  CollegeDashboardState build() => const CollegeDashboardState();

  Future<void> load() async {
    state = const CollegeDashboardState(loading: true);
    try {
      final users = await ref.read(collegeJurnalRepoProvider).fetchDashboard();
      state = CollegeDashboardState(users: users);
    } catch (e) {
      state = CollegeDashboardState(error: extractErrorMessage(e));
    }
  }
}

final collegeDashboardProvider =
    NotifierProvider<CollegeDashboardNotifier, CollegeDashboardState>(
        CollegeDashboardNotifier.new);

// ── Bible items state ──────────────────────────────────────────────────────

class CollegeBibleState {
  final bool loading;
  final List<CollegeBibleItem> items;
  final String? error;
  const CollegeBibleState({this.loading = false, this.items = const [], this.error});
}

class CollegeBibleNotifier extends Notifier<CollegeBibleState> {
  @override
  CollegeBibleState build() => const CollegeBibleState();

  Future<void> load() async {
    state = const CollegeBibleState(loading: true);
    try {
      final items = await ref.read(collegeJurnalRepoProvider).fetchBibleItems();
      state = CollegeBibleState(items: items);
    } catch (e) {
      state = CollegeBibleState(error: extractErrorMessage(e));
    }
  }
}

final collegeBibleProvider =
    NotifierProvider<CollegeBibleNotifier, CollegeBibleState>(
        CollegeBibleNotifier.new);

// ── College items state ────────────────────────────────────────────────────

class CollegeItemsState {
  final bool loading;
  final List<CollegeItem> items;
  final String? error;
  const CollegeItemsState({this.loading = false, this.items = const [], this.error});
}

class CollegeItemsNotifier extends Notifier<CollegeItemsState> {
  @override
  CollegeItemsState build() => const CollegeItemsState();

  Future<void> load() async {
    state = const CollegeItemsState(loading: true);
    try {
      final items = await ref.read(collegeJurnalRepoProvider).fetchCollegeItems();
      state = CollegeItemsState(items: items);
    } catch (e) {
      state = CollegeItemsState(error: extractErrorMessage(e));
    }
  }
}

final collegeItemsProvider =
    NotifierProvider<CollegeItemsNotifier, CollegeItemsState>(
        CollegeItemsNotifier.new);

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/prajurit_jurnal_model.dart';

// ── Repository ─────────────────────────────────────────────────────────────

class PrajuritJurnalRepository {
  final Dio _dio;
  const PrajuritJurnalRepository(this._dio);

  Future<List<PrajuritJurnalUser>> fetchDashboard() async {
    final r = await _dio.get(ApiConstants.adminJurnalPrajuritDashboard);
    final data = r.data;
    // Response may be {users: [...]} or directly a list
    List raw = data is Map ? (data['users'] ?? data['data'] ?? []) : data as List;
    return raw.map((e) => PrajuritJurnalUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PrajuritBibleItem>> fetchBibleItems() async {
    final r = await _dio.get(ApiConstants.adminJurnalPrajuritBible);
    final raw = (r.data as List?) ?? [];
    return raw.map((e) => PrajuritBibleItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PrajuritItem>> fetchPrajuritItems() async {
    final r = await _dio.get(ApiConstants.adminJurnalPrajuritItems);
    final data = r.data;
    List raw = data is Map ? (data['data'] ?? []) : data as List;
    return raw.map((e) => PrajuritItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final PrajuritJurnalRepoProvider = Provider(
  (ref) => PrajuritJurnalRepository(ref.read(dioProvider)),
);

// ── Dashboard state ────────────────────────────────────────────────────────

class PrajuritDashboardState {
  final bool loading;
  final List<PrajuritJurnalUser> users;
  final String? error;
  const PrajuritDashboardState({this.loading = false, this.users = const [], this.error});
}

class PrajuritDashboardNotifier extends Notifier<PrajuritDashboardState> {
  @override
  PrajuritDashboardState build() => const PrajuritDashboardState();

  Future<void> load() async {
    state = const PrajuritDashboardState(loading: true);
    try {
      final users = await ref.read(PrajuritJurnalRepoProvider).fetchDashboard();
      state = PrajuritDashboardState(users: users);
    } catch (e) {
      state = PrajuritDashboardState(error: extractErrorMessage(e));
    }
  }
}

final PrajuritDashboardProvider =
    NotifierProvider<PrajuritDashboardNotifier, PrajuritDashboardState>(
        PrajuritDashboardNotifier.new);

// ── Bible items state ──────────────────────────────────────────────────────

class PrajuritBibleState {
  final bool loading;
  final List<PrajuritBibleItem> items;
  final String? error;
  const PrajuritBibleState({this.loading = false, this.items = const [], this.error});
}

class PrajuritBibleNotifier extends Notifier<PrajuritBibleState> {
  @override
  PrajuritBibleState build() => const PrajuritBibleState();

  Future<void> load() async {
    state = const PrajuritBibleState(loading: true);
    try {
      final items = await ref.read(PrajuritJurnalRepoProvider).fetchBibleItems();
      state = PrajuritBibleState(items: items);
    } catch (e) {
      state = PrajuritBibleState(error: extractErrorMessage(e));
    }
  }
}

final PrajuritBibleProvider =
    NotifierProvider<PrajuritBibleNotifier, PrajuritBibleState>(
        PrajuritBibleNotifier.new);

// ── prajurit items state ────────────────────────────────────────────────────

class PrajuritItemsState {
  final bool loading;
  final List<PrajuritItem> items;
  final String? error;
  const PrajuritItemsState({this.loading = false, this.items = const [], this.error});
}

class PrajuritItemsNotifier extends Notifier<PrajuritItemsState> {
  @override
  PrajuritItemsState build() => const PrajuritItemsState();

  Future<void> load() async {
    state = const PrajuritItemsState(loading: true);
    try {
      final items = await ref.read(PrajuritJurnalRepoProvider).fetchPrajuritItems();
      state = PrajuritItemsState(items: items);
    } catch (e) {
      state = PrajuritItemsState(error: extractErrorMessage(e));
    }
  }
}

final PrajuritItemsProvider =
    NotifierProvider<PrajuritItemsNotifier, PrajuritItemsState>(
        PrajuritItemsNotifier.new);

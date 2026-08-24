import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/jurnal_monitor_model.dart';

class JurnalMonitorRepository {
  final Dio _dio;
  const JurnalMonitorRepository(this._dio);

  Future<JurnalMonitorSummary> fetchSummary() async {
    final response = await _dio.get(ApiConstants.jurnalMonitorSummary);
    return JurnalMonitorSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<JurnalMonitorUser>> fetchUsers(String role, {String? query, int page = 1}) async {
    final response = await _dio.get(
      ApiConstants.jurnalMonitorList(role),
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        'page': page,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final usersData = data['users'] as Map<String, dynamic>;
    final list = usersData['data'] as List;
    return list.map((e) => JurnalMonitorUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<JurnalMonitorDetail> fetchDetail(String role, int userId, {String? from, String? to}) async {
    final response = await _dio.get(
      ApiConstants.jurnalMonitorDetail(role, userId),
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );
    return JurnalMonitorDetail.fromJson(response.data as Map<String, dynamic>);
  }
}

final jurnalMonitorRepositoryProvider = Provider((ref) => JurnalMonitorRepository(ref.read(dioProvider)));

// ── Summary state ────────────────────────────────────────────────────────

class JurnalMonitorSummaryState {
  final bool loading;
  final JurnalMonitorSummary? summary;
  final String? error;

  const JurnalMonitorSummaryState({this.loading = false, this.summary, this.error});
}

class JurnalMonitorSummaryNotifier extends Notifier<JurnalMonitorSummaryState> {
  @override
  JurnalMonitorSummaryState build() => const JurnalMonitorSummaryState();

  Future<void> load() async {
    state = const JurnalMonitorSummaryState(loading: true);
    try {
      final summary = await ref.read(jurnalMonitorRepositoryProvider).fetchSummary();
      state = JurnalMonitorSummaryState(summary: summary);
    } catch (e) {
      state = JurnalMonitorSummaryState(error: extractErrorMessage(e));
    }
  }
}

final jurnalMonitorSummaryProvider =
    NotifierProvider<JurnalMonitorSummaryNotifier, JurnalMonitorSummaryState>(
        JurnalMonitorSummaryNotifier.new);

// ── Per-role user list state ────────────────────────────────────────────

class JurnalMonitorListState {
  final bool loading;
  final List<JurnalMonitorUser> users;
  final String? error;
  final String query;

  const JurnalMonitorListState({
    this.loading = false,
    this.users = const [],
    this.error,
    this.query = '',
  });

  JurnalMonitorListState copyWith({
    bool? loading,
    List<JurnalMonitorUser>? users,
    String? error,
    String? query,
  }) =>
      JurnalMonitorListState(
        loading: loading ?? this.loading,
        users: users ?? this.users,
        error: error,
        query: query ?? this.query,
      );
}

class JurnalMonitorListNotifier extends FamilyNotifier<JurnalMonitorListState, String> {
  late final String role;

  @override
  JurnalMonitorListState build(String arg) {
    role = arg;
    return const JurnalMonitorListState();
  }

  Future<void> load({String? query}) async {
    state = state.copyWith(loading: true, error: null, query: query ?? state.query);
    try {
      final users = await ref
          .read(jurnalMonitorRepositoryProvider)
          .fetchUsers(role, query: query ?? state.query);
      state = state.copyWith(loading: false, users: users);
    } catch (e) {
      state = state.copyWith(loading: false, error: extractErrorMessage(e));
    }
  }
}

final jurnalMonitorListProvider =
    NotifierProvider.family<JurnalMonitorListNotifier, JurnalMonitorListState, String>(
        JurnalMonitorListNotifier.new);

// ── Detail (matrix) state ───────────────────────────────────────────────

class JurnalMonitorDetailState {
  final bool loading;
  final JurnalMonitorDetail? detail;
  final String? error;

  const JurnalMonitorDetailState({this.loading = false, this.detail, this.error});
}

class JurnalMonitorDetailArgs {
  final String role;
  final int userId;
  const JurnalMonitorDetailArgs(this.role, this.userId);

  @override
  bool operator ==(Object other) =>
      other is JurnalMonitorDetailArgs && other.role == role && other.userId == userId;

  @override
  int get hashCode => Object.hash(role, userId);
}

class JurnalMonitorDetailNotifier
    extends FamilyNotifier<JurnalMonitorDetailState, JurnalMonitorDetailArgs> {
  late JurnalMonitorDetailArgs args;

  @override
  JurnalMonitorDetailState build(JurnalMonitorDetailArgs arg) {
    args = arg;
    return const JurnalMonitorDetailState();
  }

  Future<void> load({String? from, String? to}) async {
    state = const JurnalMonitorDetailState(loading: true);
    try {
      final detail = await ref
          .read(jurnalMonitorRepositoryProvider)
          .fetchDetail(args.role, args.userId, from: from, to: to);
      state = JurnalMonitorDetailState(detail: detail);
    } catch (e) {
      state = JurnalMonitorDetailState(error: extractErrorMessage(e));
    }
  }
}

final jurnalMonitorDetailProvider = NotifierProvider.family<JurnalMonitorDetailNotifier,
    JurnalMonitorDetailState, JurnalMonitorDetailArgs>(JurnalMonitorDetailNotifier.new);

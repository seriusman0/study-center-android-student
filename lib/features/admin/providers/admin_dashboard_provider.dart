import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';

class AdminDashboardStats {
  final List<MapEntry<String, int>> usersByRole;
  final int totalUsers;
  final int totalBlogs;
  final int totalComments;

  const AdminDashboardStats({
    required this.usersByRole,
    required this.totalUsers,
    required this.totalBlogs,
    required this.totalComments,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['users_by_role'] as List? ?? [];
    return AdminDashboardStats(
      usersByRole: rolesRaw
          .map((e) => MapEntry(
                (e['role'] as String?) ?? '',
                ((e['total'] as num?) ?? 0).toInt(),
              ))
          .toList(),
      totalUsers: (json['total_users'] as num?)?.toInt() ?? 0,
      totalBlogs: (json['total_blogs'] as num?)?.toInt() ?? 0,
      totalComments: (json['total_comments'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminDashboardRepository {
  final Dio _dio;
  const AdminDashboardRepository(this._dio);

  Future<AdminDashboardStats> fetch() async {
    final response = await _dio.get(ApiConstants.adminDashboard);
    return AdminDashboardStats.fromJson(response.data as Map<String, dynamic>);
  }
}

final adminDashboardRepositoryProvider =
    Provider((ref) => AdminDashboardRepository(ref.read(dioProvider)));

class AdminDashboardState {
  final bool loading;
  final AdminDashboardStats? stats;
  final String? error;

  const AdminDashboardState({this.loading = false, this.stats, this.error});
}

class AdminDashboardNotifier extends Notifier<AdminDashboardState> {
  @override
  AdminDashboardState build() => const AdminDashboardState();

  Future<void> load() async {
    state = const AdminDashboardState(loading: true);
    try {
      final stats = await ref.read(adminDashboardRepositoryProvider).fetch();
      state = AdminDashboardState(stats: stats);
    } catch (e) {
      state = AdminDashboardState(error: extractErrorMessage(e));
    }
  }
}

final adminDashboardProvider =
    NotifierProvider<AdminDashboardNotifier, AdminDashboardState>(AdminDashboardNotifier.new);

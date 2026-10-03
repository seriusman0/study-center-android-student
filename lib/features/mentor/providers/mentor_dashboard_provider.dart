import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';

class MentorDashboardStats {
  final int totalKelas;
  final int totalMurid;

  const MentorDashboardStats({this.totalKelas = 0, this.totalMurid = 0});
}

class MentorDashboardState {
  final bool loading;
  final MentorDashboardStats stats;
  final String? error;

  const MentorDashboardState({
    this.loading = false,
    this.stats = const MentorDashboardStats(),
    this.error,
  });

  MentorDashboardState copyWith({bool? loading, MentorDashboardStats? stats, String? error}) {
    return MentorDashboardState(
      loading: loading ?? this.loading,
      stats: stats ?? this.stats,
      error: error,
    );
  }
}

class MentorDashboardNotifier extends StateNotifier<MentorDashboardState> {
  final Dio _dio;

  MentorDashboardNotifier(this._dio) : super(const MentorDashboardState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);

      final from = DateFormat('yyyy-MM-dd').format(firstDay);
      final to = DateFormat('yyyy-MM-dd').format(lastDay);

      int totalKelas = 0;
      int totalMurid = 0;

      int page = 1;
      int lastPage = 1;

      do {
        final res = await _dio.get(ApiConstants.presensi, queryParameters: {
          'from': from,
          'to': to,
          'page': page,
        });

        final data = res.data as Map<String, dynamic>;
        final items = data['data'] as List;
        
        totalKelas += items.length;
        for (var item in items) {
          final count = item['students_count'];
          if (count != null) {
            totalMurid += (count is int) ? count : int.tryParse(count.toString()) ?? 0;
          }
        }

        final meta = data['meta'] as Map<String, dynamic>?;
        if (meta != null) {
          lastPage = (meta['last_page'] as num?)?.toInt() ?? 1;
        }
        page++;
      } while (page <= lastPage);

      state = state.copyWith(
        loading: false,
        stats: MentorDashboardStats(totalKelas: totalKelas, totalMurid: totalMurid),
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final mentorDashboardProvider = StateNotifierProvider<MentorDashboardNotifier, MentorDashboardState>((ref) {
  return MentorDashboardNotifier(ref.read(dioProvider));
});

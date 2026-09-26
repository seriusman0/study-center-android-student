import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/mentor_presensi_admin_model.dart';

class MentorPresensiAdminRepository {
  final Dio _dio;
  const MentorPresensiAdminRepository(this._dio);

  Future<List<MentorPresensiEntry>> fetchList({String? from, String? to}) async {
    final response = await _dio.get(ApiConstants.adminMentorPresensi, queryParameters: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
    final data = response.data as Map<String, dynamic>;
    final paginator = data['data'] as Map<String, dynamic>?;
    final list = paginator?['data'] as List? ?? [];
    return list.map((e) => MentorPresensiEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MentorPresensiReport> fetchReports({String? from, String? to}) async {
    final response = await _dio.get(ApiConstants.adminMentorPresensiReports, queryParameters: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
    return MentorPresensiReport.fromJson(response.data as Map<String, dynamic>);
  }

  /// Downloads an export file (Excel/CSV or PDF) with the auth header
  /// attached, since these endpoints require a bearer token — a plain
  /// url_launcher open would 401. Saves to the app's temp dir and returns
  /// the local path so the caller can open it with open_filex.
  Future<String> downloadExport({
    required String endpoint,
    required String filename,
    String? from,
    String? to,
  }) async {
    final dir = await getTemporaryDirectory();
    final savePath = '${dir.path}/$filename';
    await _dio.download(
      endpoint,
      savePath,
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );
    debugPrint('[MENTOR-PRESENSI] Export downloaded to $savePath');
    return savePath;
  }
}

final mentorPresensiAdminRepositoryProvider =
    Provider((ref) => MentorPresensiAdminRepository(ref.read(dioProvider)));

class MentorPresensiAdminState {
  final bool loading;
  final List<MentorPresensiEntry> entries;
  final MentorPresensiReport? report;
  final bool exporting;
  final String? error;

  const MentorPresensiAdminState({
    this.loading = false,
    this.entries = const [],
    this.report,
    this.exporting = false,
    this.error,
  });

  MentorPresensiAdminState copyWith({
    bool? loading,
    List<MentorPresensiEntry>? entries,
    MentorPresensiReport? report,
    bool? exporting,
    String? error,
    bool clearError = false,
  }) {
    return MentorPresensiAdminState(
      loading: loading ?? this.loading,
      entries: entries ?? this.entries,
      report: report ?? this.report,
      exporting: exporting ?? this.exporting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MentorPresensiAdminNotifier extends Notifier<MentorPresensiAdminState> {
  @override
  MentorPresensiAdminState build() => const MentorPresensiAdminState();

  Future<void> load({String? from, String? to}) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final results = await Future.wait([
        ref.read(mentorPresensiAdminRepositoryProvider).fetchList(from: from, to: to),
        ref.read(mentorPresensiAdminRepositoryProvider).fetchReports(from: from, to: to),
      ]);
      state = state.copyWith(
        loading: false,
        entries: results[0] as List<MentorPresensiEntry>,
        report: results[1] as MentorPresensiReport,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: extractErrorMessage(e));
    }
  }

  /// Returns the local file path on success, null on failure.
  Future<String?> exportExcel({String? from, String? to}) async {
    state = state.copyWith(exporting: true, clearError: true);
    try {
      final path = await ref.read(mentorPresensiAdminRepositoryProvider).downloadExport(
            endpoint: ApiConstants.adminMentorPresensiExportExcel,
            filename: 'laporan-presensi-mentor-${DateTime.now().millisecondsSinceEpoch}.csv',
            from: from,
            to: to,
          );
      state = state.copyWith(exporting: false);
      return path;
    } catch (e) {
      state = state.copyWith(exporting: false, error: extractErrorMessage(e));
      return null;
    }
  }

  Future<String?> exportPdf({String? from, String? to}) async {
    state = state.copyWith(exporting: true, clearError: true);
    try {
      final path = await ref.read(mentorPresensiAdminRepositoryProvider).downloadExport(
            endpoint: ApiConstants.adminMentorPresensiExportPdf,
            filename: 'laporan-presensi-mentor-${DateTime.now().millisecondsSinceEpoch}.pdf',
            from: from,
            to: to,
          );
      state = state.copyWith(exporting: false);
      return path;
    } catch (e) {
      state = state.copyWith(exporting: false, error: extractErrorMessage(e));
      return null;
    }
  }
}

final mentorPresensiAdminProvider =
    NotifierProvider<MentorPresensiAdminNotifier, MentorPresensiAdminState>(
        MentorPresensiAdminNotifier.new);

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/certificate_model.dart';

/// Name tags: /admin/nametags returns the pool of active students eligible
/// for a name tag, /admin/nametags/generate returns render data (width,
/// height, selected students) for the client to lay out as a printable
/// tag. There is no persisted "already generated" list server-side —
/// generation is done client-side per selection, so this provider tracks
/// the eligible student pool + the current generation result in-session.
class NameTagsRepository {
  final Dio _dio;
  const NameTagsRepository(this._dio);

  Future<List<StudentOption>> fetchStudents({String? q, int? cabangId}) async {
    final response = await _dio.get(ApiConstants.adminNameTags, queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (cabangId != null) 'cabang_id': cabangId,
    });
    final data = response.data as Map<String, dynamic>;
    final paginator = data['data'] as Map<String, dynamic>?;
    final list = paginator?['data'] as List? ?? [];
    return list.map((e) => StudentOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<NameTagGenerateResult> generate({
    required List<int> userIds,
    double? widthCm,
    double? heightCm,
  }) async {
    final response = await _dio.post(ApiConstants.adminNameTagsGenerate, data: {
      'user_ids': userIds,
      if (widthCm != null) 'width_cm': widthCm,
      if (heightCm != null) 'height_cm': heightCm,
    });
    return NameTagGenerateResult.fromJson(response.data as Map<String, dynamic>);
  }
}

class NameTagGenerateResult {
  final double widthCm;
  final double heightCm;
  final List<StudentOption> students;

  const NameTagGenerateResult({
    required this.widthCm,
    required this.heightCm,
    required this.students,
  });

  factory NameTagGenerateResult.fromJson(Map<String, dynamic> json) {
    final studentsRaw = json['students'] as List? ?? [];
    return NameTagGenerateResult(
      widthCm: (json['width_cm'] as num?)?.toDouble() ?? 8.5,
      heightCm: (json['height_cm'] as num?)?.toDouble() ?? 5.5,
      students:
          studentsRaw.map((e) => StudentOption.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

final nameTagsRepositoryProvider = Provider((ref) => NameTagsRepository(ref.read(dioProvider)));

class NameTagsState {
  final bool loading;
  final List<StudentOption> students;
  final Set<int> selectedIds;
  final String? error;
  final bool generating;
  final NameTagGenerateResult? result;

  const NameTagsState({
    this.loading = false,
    this.students = const [],
    this.selectedIds = const {},
    this.error,
    this.generating = false,
    this.result,
  });

  NameTagsState copyWith({
    bool? loading,
    List<StudentOption>? students,
    Set<int>? selectedIds,
    String? error,
    bool? generating,
    NameTagGenerateResult? result,
    bool clearError = false,
  }) {
    return NameTagsState(
      loading: loading ?? this.loading,
      students: students ?? this.students,
      selectedIds: selectedIds ?? this.selectedIds,
      error: clearError ? null : (error ?? this.error),
      generating: generating ?? this.generating,
      result: result ?? this.result,
    );
  }
}

class NameTagsNotifier extends Notifier<NameTagsState> {
  @override
  NameTagsState build() => const NameTagsState();

  Future<void> load({String? q}) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final students = await ref.read(nameTagsRepositoryProvider).fetchStudents(q: q);
      state = state.copyWith(loading: false, students: students);
    } catch (e) {
      state = state.copyWith(loading: false, error: extractErrorMessage(e));
    }
  }

  void toggleSelected(int userId) {
    final updated = Set<int>.from(state.selectedIds);
    if (updated.contains(userId)) {
      updated.remove(userId);
    } else {
      updated.add(userId);
    }
    state = state.copyWith(selectedIds: updated);
  }

  void clearSelection() => state = state.copyWith(selectedIds: {});

  Future<bool> generate({double? widthCm, double? heightCm}) async {
    if (state.selectedIds.isEmpty) return false;
    state = state.copyWith(generating: true, clearError: true);
    try {
      final result = await ref.read(nameTagsRepositoryProvider).generate(
            userIds: state.selectedIds.toList(),
            widthCm: widthCm,
            heightCm: heightCm,
          );
      state = state.copyWith(generating: false, result: result);
      return true;
    } catch (e) {
      state = state.copyWith(generating: false, error: extractErrorMessage(e));
      return false;
    }
  }
}

final nameTagsProvider = NotifierProvider<NameTagsNotifier, NameTagsState>(NameTagsNotifier.new);

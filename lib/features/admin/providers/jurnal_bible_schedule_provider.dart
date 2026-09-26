import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/jurnal_config_model.dart';

class JurnalBibleScheduleRepository {
  final Dio _dio;
  const JurnalBibleScheduleRepository(this._dio);

  Future<List<JurnalBibleSchedule>> fetch({required int bulan, required int tahun}) async {
    final response = await _dio.get(
      ApiConstants.adminJurnalBibleSchedules,
      queryParameters: {'bulan': bulan, 'tahun': tahun},
    );
    final data = (response.data as Map<String, dynamic>)['data'] as List? ?? [];
    return data.map((e) => JurnalBibleSchedule.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> create(JurnalBibleSchedule item) async {
    await _dio.post(ApiConstants.adminJurnalBibleSchedules, data: item.toJson());
  }

  Future<void> update(int id, JurnalBibleSchedule item) async {
    await _dio.put(ApiConstants.adminJurnalBibleScheduleDetail(id), data: item.toJson());
  }

  Future<void> delete(int id) async {
    await _dio.delete(ApiConstants.adminJurnalBibleScheduleDetail(id));
  }
}

final jurnalBibleScheduleRepositoryProvider =
    Provider((ref) => JurnalBibleScheduleRepository(ref.read(dioProvider)));

class JurnalBibleScheduleState {
  final bool loading;
  final List<JurnalBibleSchedule> items;
  final int bulan;
  final int tahun;
  final String? error;

  const JurnalBibleScheduleState({
    this.loading = false,
    this.items = const [],
    required this.bulan,
    required this.tahun,
    this.error,
  });

  JurnalBibleScheduleState copyWith({
    bool? loading,
    List<JurnalBibleSchedule>? items,
    int? bulan,
    int? tahun,
    String? error,
    bool clearError = false,
  }) {
    return JurnalBibleScheduleState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      bulan: bulan ?? this.bulan,
      tahun: tahun ?? this.tahun,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class JurnalBibleScheduleNotifier extends Notifier<JurnalBibleScheduleState> {
  @override
  JurnalBibleScheduleState build() {
    final now = DateTime.now();
    return JurnalBibleScheduleState(bulan: now.month, tahun: now.year);
  }

  Future<void> load({int? bulan, int? tahun}) async {
    final m = bulan ?? state.bulan;
    final y = tahun ?? state.tahun;
    state = state.copyWith(loading: true, bulan: m, tahun: y, clearError: true);
    try {
      final items =
          await ref.read(jurnalBibleScheduleRepositoryProvider).fetch(bulan: m, tahun: y);
      state = state.copyWith(loading: false, items: items, clearError: true);
    } catch (e) {
      state = state.copyWith(loading: false, error: extractErrorMessage(e));
    }
  }

  Future<bool> create(JurnalBibleSchedule item) async {
    try {
      await ref.read(jurnalBibleScheduleRepositoryProvider).create(item);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
      return false;
    }
  }

  Future<bool> update(int id, JurnalBibleSchedule item) async {
    try {
      await ref.read(jurnalBibleScheduleRepositoryProvider).update(id, item);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await ref.read(jurnalBibleScheduleRepositoryProvider).delete(id);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
      return false;
    }
  }
}

final jurnalBibleScheduleProvider =
    NotifierProvider<JurnalBibleScheduleNotifier, JurnalBibleScheduleState>(
        JurnalBibleScheduleNotifier.new);

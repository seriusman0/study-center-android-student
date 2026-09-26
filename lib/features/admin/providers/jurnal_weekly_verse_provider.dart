import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/jurnal_config_model.dart';

class JurnalWeeklyVerseRepository {
  final Dio _dio;
  const JurnalWeeklyVerseRepository(this._dio);

  Future<List<JurnalWeeklyVerse>> fetch({required int tahun}) async {
    final response = await _dio.get(
      ApiConstants.adminJurnalWeeklyVerses,
      queryParameters: {'tahun': tahun},
    );
    final data = (response.data as Map<String, dynamic>)['data'] as List? ?? [];
    return data.map((e) => JurnalWeeklyVerse.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> create(JurnalWeeklyVerse item) async {
    await _dio.post(ApiConstants.adminJurnalWeeklyVerses, data: item.toJson());
  }

  Future<void> update(int id, JurnalWeeklyVerse item) async {
    await _dio.put(ApiConstants.adminJurnalWeeklyVerseDetail(id), data: item.toJson());
  }

  Future<void> delete(int id) async {
    await _dio.delete(ApiConstants.adminJurnalWeeklyVerseDetail(id));
  }
}

final jurnalWeeklyVerseRepositoryProvider =
    Provider((ref) => JurnalWeeklyVerseRepository(ref.read(dioProvider)));

class JurnalWeeklyVerseState {
  final bool loading;
  final List<JurnalWeeklyVerse> items;
  final int tahun;
  final String? error;

  const JurnalWeeklyVerseState({
    this.loading = false,
    this.items = const [],
    required this.tahun,
    this.error,
  });

  JurnalWeeklyVerseState copyWith({
    bool? loading,
    List<JurnalWeeklyVerse>? items,
    int? tahun,
    String? error,
    bool clearError = false,
  }) {
    return JurnalWeeklyVerseState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      tahun: tahun ?? this.tahun,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class JurnalWeeklyVerseNotifier extends Notifier<JurnalWeeklyVerseState> {
  @override
  JurnalWeeklyVerseState build() {
    final now = DateTime.now();
    return JurnalWeeklyVerseState(tahun: now.year);
  }

  Future<void> load({int? tahun}) async {
    final y = tahun ?? state.tahun;
    state = state.copyWith(loading: true, tahun: y, clearError: true);
    try {
      final items = await ref.read(jurnalWeeklyVerseRepositoryProvider).fetch(tahun: y);
      state = state.copyWith(loading: false, items: items, clearError: true);
    } catch (e) {
      state = state.copyWith(loading: false, error: extractErrorMessage(e));
    }
  }

  Future<bool> create(JurnalWeeklyVerse item) async {
    try {
      await ref.read(jurnalWeeklyVerseRepositoryProvider).create(item);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
      return false;
    }
  }

  Future<bool> update(int id, JurnalWeeklyVerse item) async {
    try {
      await ref.read(jurnalWeeklyVerseRepositoryProvider).update(id, item);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await ref.read(jurnalWeeklyVerseRepositoryProvider).delete(id);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
      return false;
    }
  }
}

final jurnalWeeklyVerseProvider =
    NotifierProvider<JurnalWeeklyVerseNotifier, JurnalWeeklyVerseState>(
        JurnalWeeklyVerseNotifier.new);

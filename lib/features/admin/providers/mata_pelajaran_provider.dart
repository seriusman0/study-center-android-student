import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/mata_pelajaran_model.dart';

class MataPelajaranRepository {
  final Dio _dio;
  const MataPelajaranRepository(this._dio);

  Future<List<MataPelajaranModel>> fetchAll() async {
    final response = await _dio.get(ApiConstants.adminMataPelajaran);
    final list = response.data as List? ?? [];
    return list.map((e) => MataPelajaranModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> create({required String nama, int? urutan}) async {
    await _dio.post(ApiConstants.adminMataPelajaran, data: {
      'nama': nama,
      if (urutan != null) 'urutan': urutan,
    });
  }

  Future<void> update(int id, {required String nama, int? urutan, bool? isActive}) async {
    await _dio.put(ApiConstants.adminMataPelajaranDetail(id), data: {
      'nama': nama,
      if (urutan != null) 'urutan': urutan,
      if (isActive != null) 'is_active': isActive,
    });
  }

  Future<void> toggleActive(int id) async {
    await _dio.patch(ApiConstants.adminMataPelajaranToggle(id));
  }

  Future<void> delete(int id) async {
    await _dio.delete(ApiConstants.adminMataPelajaranDetail(id));
  }
}

final mataPelajaranRepositoryProvider =
    Provider((ref) => MataPelajaranRepository(ref.read(dioProvider)));

class MataPelajaranState {
  final bool loading;
  final List<MataPelajaranModel> items;
  final String? error;

  const MataPelajaranState({this.loading = false, this.items = const [], this.error});

  MataPelajaranState copyWith({bool? loading, List<MataPelajaranModel>? items, String? error}) =>
      MataPelajaranState(
        loading: loading ?? this.loading,
        items: items ?? this.items,
        error: error,
      );
}

class MataPelajaranNotifier extends Notifier<MataPelajaranState> {
  @override
  MataPelajaranState build() => const MataPelajaranState();

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final items = await ref.read(mataPelajaranRepositoryProvider).fetchAll();
      state = state.copyWith(loading: false, items: items);
    } catch (e) {
      state = state.copyWith(loading: false, error: extractErrorMessage(e));
    }
  }

  Future<bool> create({required String nama, int? urutan}) async {
    try {
      await ref.read(mataPelajaranRepositoryProvider).create(nama: nama, urutan: urutan);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update(int id, {required String nama, int? urutan, bool? isActive}) async {
    try {
      await ref.read(mataPelajaranRepositoryProvider).update(id, nama: nama, urutan: urutan, isActive: isActive);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleActive(int id) async {
    try {
      await ref.read(mataPelajaranRepositoryProvider).toggleActive(id);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await ref.read(mataPelajaranRepositoryProvider).delete(id);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final mataPelajaranProvider =
    NotifierProvider<MataPelajaranNotifier, MataPelajaranState>(MataPelajaranNotifier.new);

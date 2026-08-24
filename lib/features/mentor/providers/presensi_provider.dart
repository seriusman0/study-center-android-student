import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/presensi_model.dart';
import '../repositories/presensi_repository.dart';

class PresensiState {
  final List<Presensi> items;
  final bool loading;
  final String? error;

  const PresensiState({this.items = const [], this.loading = false, this.error});

  PresensiState copyWith({List<Presensi>? items, bool? loading, String? error}) => PresensiState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        error: error,
      );
}

class PresensiNotifier extends Notifier<PresensiState> {
  @override
  PresensiState build() => const PresensiState();

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final items = await ref.read(presensiRepositoryProvider).list();
      state = state.copyWith(items: items, loading: false);
    } catch (e) {
      debugPrint('[Presensi] load() error: $e');
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> create({
    required int mentorId,
    required int kelasId,
    required String tanggal,
    required String jamMulai,
    required String jamSelesai,
    required String materi,
    required List<int> studentIds,
    required Map<int, String> studentStatus,
    List<int>? fotoBytes,
    String? fotoFilename,
  }) async {
    try {
      await ref.read(presensiRepositoryProvider).create(
            mentorId: mentorId,
            kelasId: kelasId,
            tanggal: tanggal,
            jamMulai: jamMulai,
            jamSelesai: jamSelesai,
            materi: materi,
            studentIds: studentIds,
            studentStatus: studentStatus,
            fotoBytes: fotoBytes,
            fotoFilename: fotoFilename,
          );
      await load();
      return true;
    } catch (e) {
      debugPrint('[Presensi] create() error: $e');
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await ref.read(presensiRepositoryProvider).delete(id);
      await load();
      return true;
    } catch (e) {
      debugPrint('[Presensi] delete() error: $e');
      return false;
    }
  }
}

final presensiProvider = NotifierProvider<PresensiNotifier, PresensiState>(PresensiNotifier.new);

/// Roster search results shown while building a new attendance session.
class StudentSearchNotifier extends AutoDisposeNotifier<List<StudentSearchResult>> {
  @override
  List<StudentSearchResult> build() => [];

  Future<void> search(String q) async {
    try {
      state = await ref.read(presensiRepositoryProvider).searchStudents(q: q);
    } catch (e) {
      debugPrint('[StudentSearch] error: $e');
    }
  }
}

final studentSearchProvider =
    AutoDisposeNotifierProvider<StudentSearchNotifier, List<StudentSearchResult>>(
        StudentSearchNotifier.new);

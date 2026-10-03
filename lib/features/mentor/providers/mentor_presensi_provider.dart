import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mentor_presensi_model.dart';
import '../repositories/mentor_presensi_repository.dart';

class MentorPresensiState {
  final bool loading;
  final String? error;
  final List<MentorPresensi> items;

  MentorPresensiState({
    this.loading = false,
    this.error,
    this.items = const [],
  });

  MentorPresensiState copyWith({bool? loading, String? error, List<MentorPresensi>? items, bool clearError = false}) {
    return MentorPresensiState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      items: items ?? this.items,
    );
  }
}

class MentorPresensiNotifier extends StateNotifier<MentorPresensiState> {
  final MentorPresensiRepository _repo;

  MentorPresensiNotifier(this._repo) : super(MentorPresensiState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final res = await _repo.list();
      state = state.copyWith(loading: false, items: res);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> create({
    required int kelasId,
    required String tanggal,
    required String jamDatang,
    required String jamPulang,
    required int jumlahMurid,
    String? catatan,
  }) async {
    try {
      await _repo.create(
        kelasId: kelasId,
        tanggal: tanggal,
        jamDatang: jamDatang,
        jamPulang: jamPulang,
        jumlahMurid: jumlahMurid,
        catatan: catatan,
      );
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateItem(int id, {
    required int kelasId,
    required String tanggal,
    required String jamDatang,
    required String jamPulang,
    required int jumlahMurid,
    String? catatan,
  }) async {
    try {
      await _repo.update(
        id: id,
        kelasId: kelasId,
        tanggal: tanggal,
        jamDatang: jamDatang,
        jamPulang: jamPulang,
        jumlahMurid: jumlahMurid,
        catatan: catatan,
      );
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> destroy(int id) async {
    try {
      await _repo.delete(id);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final mentorPresensiProvider = StateNotifierProvider<MentorPresensiNotifier, MentorPresensiState>((ref) {
  return MentorPresensiNotifier(ref.read(mentorPresensiRepositoryProvider));
});


import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kelas_master_model.dart';
import '../repositories/kelas_master_repository.dart';

class KelasMasterState {
  final List<KelasMaster> items;
  final bool loading;
  final String? error;

  const KelasMasterState({this.items = const [], this.loading = false, this.error});

  KelasMasterState copyWith({List<KelasMaster>? items, bool? loading, String? error}) =>
      KelasMasterState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        error: error,
      );
}

class KelasMasterNotifier extends Notifier<KelasMasterState> {
  @override
  KelasMasterState build() => const KelasMasterState();

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final items = await ref.read(kelasMasterRepositoryProvider).list();
      state = state.copyWith(items: items, loading: false);
    } catch (e) {
      debugPrint('[KelasMaster] load() error: $e');
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> create({required String nama, required int cabangId, String? keterangan}) async {
    try {
      await ref.read(kelasMasterRepositoryProvider).create(
            nama: nama,
            cabangId: cabangId,
            keterangan: keterangan,
          );
      await load();
      return true;
    } catch (e) {
      debugPrint('[KelasMaster] create() error: $e');
      return false;
    }
  }

  Future<bool> update({
    required int id,
    required String nama,
    required int cabangId,
    String? keterangan,
    bool isActive = true,
  }) async {
    try {
      await ref.read(kelasMasterRepositoryProvider).update(
            id: id,
            nama: nama,
            cabangId: cabangId,
            keterangan: keterangan,
            isActive: isActive,
          );
      await load();
      return true;
    } catch (e) {
      debugPrint('[KelasMaster] update() error: $e');
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await ref.read(kelasMasterRepositoryProvider).delete(id);
      await load();
      return true;
    } catch (e) {
      debugPrint('[KelasMaster] delete() error: $e');
      return false;
    }
  }
}

final kelasMasterProvider =
    NotifierProvider<KelasMasterNotifier, KelasMasterState>(KelasMasterNotifier.new);

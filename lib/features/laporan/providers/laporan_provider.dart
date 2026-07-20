import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/laporan_model.dart';
import '../repositories/laporan_repository.dart';

class LaporanState {
  final LaporanSummary? summary;
  final LaporanMatrix? matrix;
  final bool loading;
  final String? error;

  const LaporanState({this.summary, this.matrix, this.loading = false, this.error});

  LaporanState copyWith({LaporanSummary? summary, LaporanMatrix? matrix, bool? loading, String? error}) =>
      LaporanState(
        summary: summary ?? this.summary,
        matrix:  matrix ?? this.matrix,
        loading: loading ?? this.loading,
        error:   error,
      );
}

class LaporanNotifier extends Notifier<LaporanState> {
  @override
  LaporanState build() => const LaporanState();

  Future<void> load({String? from, String? to}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final summary = await ref.read(laporanRepositoryProvider).summary();
      final matrix  = await ref.read(laporanRepositoryProvider).matrix(from: from, to: to);
      state = state.copyWith(summary: summary, matrix: matrix, loading: false);
    } catch (e) {
      state = LaporanState(error: e.toString());
    }
  }
}

final laporanProvider = NotifierProvider<LaporanNotifier, LaporanState>(LaporanNotifier.new);

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../laporan/models/laporan_model.dart';
import '../models/home_model.dart';
import '../repositories/home_repository.dart';

class HomeState {
  final List<BlogPost> blogs;
  final List<GaleriItem> galeri;
  final LaporanSummary? laporan;
  final bool loading;
  final String? error;

  const HomeState({
    this.blogs = const [],
    this.galeri = const [],
    this.laporan,
    this.loading = false,
    this.error,
  });

  HomeState copyWith({
    List<BlogPost>? blogs,
    List<GaleriItem>? galeri,
    LaporanSummary? laporan,
    bool? loading,
    String? error,
  }) =>
      HomeState(
        blogs:    blogs    ?? this.blogs,
        galeri:   galeri   ?? this.galeri,
        laporan:  laporan  ?? this.laporan,
        loading:  loading  ?? this.loading,
        error:    error,
      );
}

class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState();

  Future<void> load(String? cabangSlug) async {
    if (state.loading) return;
    state = state.copyWith(loading: true, error: null);
    final repo = ref.read(homeRepositoryProvider);

    List<BlogPost> blogs;
    try {
      blogs = await repo.fetchBlogs(cabangSlug);
    } catch (e) {
      debugPrint('fetchBlogs error: $e');
      blogs = [];
    }

    List<GaleriItem> galeri;
    try {
      galeri = await repo.fetchGaleri();
    } catch (e) {
      debugPrint('fetchGaleri error: $e');
      galeri = [];
    }

    LaporanSummary? laporan;
    try {
      laporan = await repo.fetchLaporan();
    } catch (e) {
      debugPrint('fetchLaporan error: $e');
    }

    state = HomeState(
      blogs:   blogs,
      galeri:  galeri,
      laporan: laporan,
      loading: false,
    );
  }
}

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);

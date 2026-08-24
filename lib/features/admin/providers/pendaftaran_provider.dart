import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/pendaftaran_model.dart';

class PendaftaranRepository {
  final Dio _dio;
  const PendaftaranRepository(this._dio);

  Future<List<PendaftaranItem>> fetchList({String status = 'semua', String? search}) async {
    final response = await _dio.get(ApiConstants.adminPendaftaran, queryParameters: {
      'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List? ?? [];
    return list.map((e) => PendaftaranItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PendaftaranItem> fetchDetail(int userId) async {
    final response = await _dio.get(ApiConstants.adminPendaftaranDetail(userId));
    return PendaftaranItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> validasi({
    required int userId,
    required String status, // diterima | ditolak | perbaikan
    String? catatanAdmin,
  }) async {
    await _dio.post(ApiConstants.adminPendaftaranValidasi(userId), data: {
      'status': status,
      if (catatanAdmin != null && catatanAdmin.isNotEmpty) 'catatan_admin': catatanAdmin,
    });
  }
}

final pendaftaranRepositoryProvider =
    Provider((ref) => PendaftaranRepository(ref.read(dioProvider)));

class PendaftaranListState {
  final bool loading;
  final List<PendaftaranItem> items;
  final String statusFilter;
  final String? error;

  const PendaftaranListState({
    this.loading = false,
    this.items = const [],
    this.statusFilter = 'semua',
    this.error,
  });
}

class PendaftaranListNotifier extends Notifier<PendaftaranListState> {
  @override
  PendaftaranListState build() => const PendaftaranListState();

  Future<void> load({String? status, String? query}) async {
    final effectiveStatus = status ?? state.statusFilter;
    state = PendaftaranListState(
        loading: true, items: state.items, statusFilter: effectiveStatus);
    try {
      final items = await ref
          .read(pendaftaranRepositoryProvider)
          .fetchList(status: effectiveStatus, search: query);
      state = PendaftaranListState(items: items, statusFilter: effectiveStatus);
    } catch (e) {
      state = PendaftaranListState(
        error: extractErrorMessage(e),
        items: state.items,
        statusFilter: effectiveStatus,
      );
    }
  }
}

final pendaftaranListProvider =
    NotifierProvider<PendaftaranListNotifier, PendaftaranListState>(PendaftaranListNotifier.new);

// ── Detail (per-user) ───────────────────────────────────────────────────
class PendaftaranDetailState {
  final bool loading;
  final PendaftaranItem? item;
  final String? error;
  final bool submitting;

  const PendaftaranDetailState({
    this.loading = false,
    this.item,
    this.error,
    this.submitting = false,
  });
}

class PendaftaranDetailNotifier extends FamilyNotifier<PendaftaranDetailState, int> {
  @override
  PendaftaranDetailState build(int userId) => const PendaftaranDetailState();

  Future<void> load() async {
    state = const PendaftaranDetailState(loading: true);
    try {
      final item = await ref.read(pendaftaranRepositoryProvider).fetchDetail(arg);
      state = PendaftaranDetailState(item: item);
    } catch (e) {
      state = PendaftaranDetailState(error: extractErrorMessage(e));
    }
  }

  Future<bool> validasi({required String status, String? catatanAdmin}) async {
    state = PendaftaranDetailState(item: state.item, submitting: true);
    try {
      await ref
          .read(pendaftaranRepositoryProvider)
          .validasi(userId: arg, status: status, catatanAdmin: catatanAdmin);
      await load();
      return true;
    } catch (e) {
      state = PendaftaranDetailState(
        item: state.item,
        error: extractErrorMessage(e),
      );
      return false;
    }
  }
}

final pendaftaranDetailProvider =
    NotifierProvider.family<PendaftaranDetailNotifier, PendaftaranDetailState, int>(
        PendaftaranDetailNotifier.new);

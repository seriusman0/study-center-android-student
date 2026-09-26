import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/jurnal_offline_model.dart';

/// Repository for Jurnal Offline Templates + Photo Scans.
///
/// Contains all 6 data-layer methods required by the admin UI:
///   templates → fetch / upload / download / delete
///   scans     → fetch / upload
///
/// Follows the same inline-repository pattern used by
/// [JurnalLifeItemsRepository] and [JurnalBibleScheduleRepository].
class JurnalOfflineRepository {
  final Dio _dio;
  const JurnalOfflineRepository(this._dio);

  // ── Templates ──────────────────────────────────────────────────────

  /// GET /jurnal-offline-templates
  /// Returns the list of offline jurnal templates available across cabangs.
  Future<List<JurnalOfflineTemplate>> fetchTemplates() async {
    final response = await _dio.get(ApiConstants.adminJurnalOfflineTemplates);
    final data =
        (response.data as Map<String, dynamic>)['data'] as List? ?? [];
    return data
        .map((e) => JurnalOfflineTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /jurnal-offline-templates  (multipart: file + cabang_id)
  /// Uploads a new offline jurnal template PDF for the given [cabangId].
  Future<void> uploadTemplate({
    required String filePath,
    required int cabangId,
  }) async {
    final fileName = filePath.split(platformSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      'cabang_id': cabangId,
    });
    await _dio.post(ApiConstants.adminJurnalOfflineTemplates, data: formData);
  }

  /// GET /jurnal-offline-templates/{id}/download
  /// Returns the raw download URL for the template file.
  Future<String> downloadTemplate(int id) async {
    final response =
        await _dio.get(ApiConstants.adminJurnalOfflineTemplateDownload(id));
    // Backend may return { "download_url": "..." } or the URL directly.
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['download_url'] as String? ??
          data['url'] as String? ??
          '';
    }
    if (data is String) return data;
    return '';
  }

  /// DELETE /jurnal-offline-templates/{id}
  Future<void> deleteTemplate(int id) async {
    await _dio.delete(ApiConstants.adminJurnalOfflineTemplateDetail(id));
  }

  // ── Photo Scans ────────────────────────────────────────────────────

  /// GET /jurnal-photo-scans
  /// Returns the list of student-submitted photo scans of filled jurnals.
  Future<List<JurnalPhotoScan>> fetchScans() async {
    final response = await _dio.get(ApiConstants.adminJurnalPhotoScans);
    final data =
        (response.data as Map<String, dynamic>)['data'] as List? ?? [];
    return data
        .map((e) => JurnalPhotoScan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /jurnal-photo-scans  (multipart: image)
  /// Uploads a photo scan (image) for OCR/result processing.
  Future<void> uploadScan({required String filePath}) async {
    final fileName = filePath.split(platformSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    await _dio.post(ApiConstants.adminJurnalPhotoScans, data: formData);
  }
}

/// Platform-specific path separator so we can extract the basename from
/// both POSIX and Windows file paths without importing `dart:io`.
const String platformSeparator = '/';

final jurnalOfflineRepositoryProvider = Provider(
  (ref) => JurnalOfflineRepository(ref.read(dioProvider)),
);

// ── Templates state ───────────────────────────────────────────────────────

class JurnalOfflineTemplatesState {
  final bool loading;
  final List<JurnalOfflineTemplate> templates;
  final String? error;

  const JurnalOfflineTemplatesState({
    this.loading = false,
    this.templates = const [],
    this.error,
  });
}

class JurnalOfflineTemplatesNotifier
    extends Notifier<JurnalOfflineTemplatesState> {
  @override
  JurnalOfflineTemplatesState build() => const JurnalOfflineTemplatesState();

  Future<void> load() async {
    state = const JurnalOfflineTemplatesState(loading: true);
    try {
      final templates = await ref
          .read(jurnalOfflineRepositoryProvider)
          .fetchTemplates();
      state = JurnalOfflineTemplatesState(templates: templates);
    } catch (e) {
      state =
          JurnalOfflineTemplatesState(error: extractErrorMessage(e));
    }
  }

  Future<bool> upload({required String filePath, required int cabangId}) async {
    try {
      await ref
          .read(jurnalOfflineRepositoryProvider)
          .uploadTemplate(filePath: filePath, cabangId: cabangId);
      await load();
      return true;
    } catch (e) {
      state = JurnalOfflineTemplatesState(
        error: extractErrorMessage(e),
        templates: state.templates,
      );
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await ref.read(jurnalOfflineRepositoryProvider).deleteTemplate(id);
      await load();
      return true;
    } catch (e) {
      state = JurnalOfflineTemplatesState(
        error: extractErrorMessage(e),
        templates: state.templates,
      );
      return false;
    }
  }
}

final jurnalOfflineTemplatesProvider = NotifierProvider<
    JurnalOfflineTemplatesNotifier, JurnalOfflineTemplatesState>(
  JurnalOfflineTemplatesNotifier.new);

// ── Photo Scans state ─────────────────────────────────────────────────────

class JurnalPhotoScansState {
  final bool loading;
  final List<JurnalPhotoScan> scans;
  final String? error;

  const JurnalPhotoScansState({
    this.loading = false,
    this.scans = const [],
    this.error,
  });
}

class JurnalPhotoScansNotifier
    extends Notifier<JurnalPhotoScansState> {
  @override
  JurnalPhotoScansState build() => const JurnalPhotoScansState();

  Future<void> load() async {
    state = const JurnalPhotoScansState(loading: true);
    try {
      final scans =
          await ref.read(jurnalOfflineRepositoryProvider).fetchScans();
      state = JurnalPhotoScansState(scans: scans);
    } catch (e) {
      state = JurnalPhotoScansState(error: extractErrorMessage(e));
    }
  }

  Future<bool> upload({required String filePath}) async {
    try {
      await ref
          .read(jurnalOfflineRepositoryProvider)
          .uploadScan(filePath: filePath);
      await load();
      return true;
    } catch (e) {
      state = JurnalPhotoScansState(
        error: extractErrorMessage(e),
        scans: state.scans,
      );
      return false;
    }
  }
}

final jurnalPhotoScansProvider =
    NotifierProvider<JurnalPhotoScansNotifier, JurnalPhotoScansState>(
        JurnalPhotoScansNotifier.new);

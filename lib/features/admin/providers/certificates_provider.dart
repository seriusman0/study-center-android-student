import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/certificate_model.dart';

class CertificatesRepository {
  final Dio _dio;
  const CertificatesRepository(this._dio);

  // ── Templates ──────────────────────────────────────────────────────────
  Future<List<CertificateTemplate>> fetchTemplates() async {
    final response = await _dio.get(ApiConstants.adminCertTemplates);
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List? ?? [];
    return list.map((e) => CertificateTemplate.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createTemplate({
    required String nama,
    String? deskripsi,
    required String htmlContent,
    required String orientation,
    required bool isActive,
  }) async {
    await _dio.post(ApiConstants.adminCertTemplates, data: {
      'nama': nama,
      'deskripsi': deskripsi,
      'html_content': htmlContent,
      'orientation': orientation,
      'paper_size': 'a4',
      'is_active': isActive,
    });
  }

  Future<void> updateTemplate({
    required int id,
    required String nama,
    String? deskripsi,
    required String htmlContent,
    required String orientation,
    required bool isActive,
  }) async {
    await _dio.post(ApiConstants.adminCertTemplateDetail(id), data: {
      '_method': 'PUT',
      'nama': nama,
      'deskripsi': deskripsi,
      'html_content': htmlContent,
      'orientation': orientation,
      'paper_size': 'a4',
      'is_active': isActive,
    });
  }

  Future<void> deleteTemplate(int id) async {
    await _dio.delete(ApiConstants.adminCertTemplateDetail(id));
  }

  // ── Issued certificates ───────────────────────────────────────────────
  Future<List<IssuedCertificate>> fetchIssued({String? search}) async {
    final response = await _dio.get(ApiConstants.adminCertIssued, queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List? ?? [];
    return list.map((e) => IssuedCertificate.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> issueCertificate({
    required int userId,
    required int templateId,
    required String namaKursus,
    required DateTime tanggalLulus,
  }) async {
    await _dio.post(ApiConstants.adminCertIssued, data: {
      'user_id': userId,
      'template_id': templateId,
      'nama_kursus': namaKursus,
      'tanggal_lulus':
          '${tanggalLulus.year.toString().padLeft(4, '0')}-${tanggalLulus.month.toString().padLeft(2, '0')}-${tanggalLulus.day.toString().padLeft(2, '0')}',
    });
  }

  Future<void> deleteIssued(int id) async {
    await _dio.delete(ApiConstants.adminCertIssuedDetail(id));
  }

  /// Downloads the issued certificate PDF to local storage and returns the
  /// saved file path. Uses Dio directly so the auth header is attached.
  Future<String> downloadIssued(int id, String savePath) async {
    await _dio.download(ApiConstants.adminCertIssuedDownload(id), savePath);
    return savePath;
  }
}

final certificatesRepositoryProvider =
    Provider((ref) => CertificatesRepository(ref.read(dioProvider)));

// ── Templates state ─────────────────────────────────────────────────────
class CertTemplatesState {
  final bool loading;
  final List<CertificateTemplate> templates;
  final String? error;

  const CertTemplatesState({this.loading = false, this.templates = const [], this.error});
}

class CertTemplatesNotifier extends Notifier<CertTemplatesState> {
  @override
  CertTemplatesState build() => const CertTemplatesState();

  Future<void> load() async {
    state = CertTemplatesState(loading: true, templates: state.templates);
    try {
      final templates = await ref.read(certificatesRepositoryProvider).fetchTemplates();
      state = CertTemplatesState(templates: templates);
    } catch (e) {
      state = CertTemplatesState(error: extractErrorMessage(e), templates: state.templates);
    }
  }

  Future<bool> create({
    required String nama,
    String? deskripsi,
    required String htmlContent,
    required String orientation,
    required bool isActive,
  }) async {
    try {
      await ref.read(certificatesRepositoryProvider).createTemplate(
            nama: nama,
            deskripsi: deskripsi,
            htmlContent: htmlContent,
            orientation: orientation,
            isActive: isActive,
          );
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update({
    required int id,
    required String nama,
    String? deskripsi,
    required String htmlContent,
    required String orientation,
    required bool isActive,
  }) async {
    try {
      await ref.read(certificatesRepositoryProvider).updateTemplate(
            id: id,
            nama: nama,
            deskripsi: deskripsi,
            htmlContent: htmlContent,
            orientation: orientation,
            isActive: isActive,
          );
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await ref.read(certificatesRepositoryProvider).deleteTemplate(id);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final certTemplatesProvider =
    NotifierProvider<CertTemplatesNotifier, CertTemplatesState>(CertTemplatesNotifier.new);

// ── Issued certificates state ───────────────────────────────────────────
class IssuedCertificatesState {
  final bool loading;
  final List<IssuedCertificate> issued;
  final String? error;

  const IssuedCertificatesState({this.loading = false, this.issued = const [], this.error});
}

class IssuedCertificatesNotifier extends Notifier<IssuedCertificatesState> {
  @override
  IssuedCertificatesState build() => const IssuedCertificatesState();

  Future<void> load({String? search}) async {
    state = IssuedCertificatesState(loading: true, issued: state.issued);
    try {
      final issued = await ref.read(certificatesRepositoryProvider).fetchIssued(search: search);
      state = IssuedCertificatesState(issued: issued);
    } catch (e) {
      state = IssuedCertificatesState(error: extractErrorMessage(e), issued: state.issued);
    }
  }

  Future<bool> issue({
    required int userId,
    required int templateId,
    required String namaKursus,
    required DateTime tanggalLulus,
  }) async {
    try {
      await ref.read(certificatesRepositoryProvider).issueCertificate(
            userId: userId,
            templateId: templateId,
            namaKursus: namaKursus,
            tanggalLulus: tanggalLulus,
          );
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await ref.read(certificatesRepositoryProvider).deleteIssued(id);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final issuedCertificatesProvider =
    NotifierProvider<IssuedCertificatesNotifier, IssuedCertificatesState>(
        IssuedCertificatesNotifier.new);

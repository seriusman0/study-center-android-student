import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/presensi_model.dart';

class PresensiRepository {
  final Dio _dio;
  const PresensiRepository(this._dio);

  Future<List<Presensi>> list({String? from, String? to}) async {
    final res = await _dio.get(ApiConstants.presensi, queryParameters: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
    final list = (res.data as Map)['data'] as List;
    return list.map((e) => Presensi.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Presensi> detail(int id) async {
    final res = await _dio.get(ApiConstants.presensiDetail(id));
    return Presensi.fromJson((res.data as Map)['data'] as Map<String, dynamic>);
  }

  Future<List<StudentSearchResult>> searchStudents({String? q}) async {
    final res = await _dio.get(
      ApiConstants.presensiSearchStudents,
      queryParameters: q != null && q.isNotEmpty ? {'q': q} : null,
    );
    final list = (res.data as Map)['data'] as List;
    return list.map((e) => StudentSearchResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Presensi> create({
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
    final formData = FormData.fromMap({
      'mentor_id': mentorId,
      'kelas_id': kelasId,
      'tanggal': tanggal,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'materi': materi,
      for (var i = 0; i < studentIds.length; i++) 'student_ids[$i]': studentIds[i],
      for (final e in studentStatus.entries) 'student_status[${e.key}]': e.value,
      if (fotoBytes != null)
        'foto': MultipartFile.fromBytes(fotoBytes, filename: fotoFilename ?? 'foto.jpg'),
    });
    final res = await _dio.post(ApiConstants.presensi, data: formData);
    return Presensi.fromJson((res.data as Map)['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _dio.delete(ApiConstants.presensiDetail(id));
  }
}

final presensiRepositoryProvider =
    Provider((ref) => PresensiRepository(ref.read(dioProvider)));

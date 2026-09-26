import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/mentor_presensi_model.dart';

class MentorPresensiRepository {
  final Dio _dio;
  const MentorPresensiRepository(this._dio);

  Future<List<MentorPresensi>> list({String? from, String? to}) async {
    final res = await _dio.get(ApiConstants.mentorPresensi, queryParameters: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
    final list = (res.data as Map)['data'] as List;
    return list.map((e) => MentorPresensi.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MentorPresensi> create({
    required int kelasId,
    required String tanggal,
    required String jamDatang,
    required String jamPulang,
    required int jumlahMurid,
    String? catatan,
  }) async {
    final res = await _dio.post(ApiConstants.mentorPresensi, data: {
      'kelas_id': kelasId,
      'tanggal': tanggal,
      'jam_datang': jamDatang,
      'jam_pulang': jamPulang,
      'jumlah_murid': jumlahMurid,
      if (catatan != null) 'catatan': catatan,
    });
    return MentorPresensi.fromJson((res.data as Map)['data'] as Map<String, dynamic>);
  }

  Future<MentorPresensi> update({
    required int id,
    required int kelasId,
    required String tanggal,
    required String jamDatang,
    required String jamPulang,
    required int jumlahMurid,
    String? catatan,
  }) async {
    final res = await _dio.put(ApiConstants.mentorPresensiDetail(id), data: {
      'kelas_id': kelasId,
      'tanggal': tanggal,
      'jam_datang': jamDatang,
      'jam_pulang': jamPulang,
      'jumlah_murid': jumlahMurid,
      if (catatan != null) 'catatan': catatan,
    });
    return MentorPresensi.fromJson((res.data as Map)['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _dio.delete(ApiConstants.mentorPresensiDetail(id));
  }
}

final mentorPresensiRepositoryProvider =
    Provider((ref) => MentorPresensiRepository(ref.read(dioProvider)));

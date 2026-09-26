import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/kelas_master_model.dart';

class KelasMasterRepository {
  final Dio _dio;
  const KelasMasterRepository(this._dio);

  Future<List<KelasMaster>> list({bool activeOnly = true}) async {
    final res = await _dio.get(
      ApiConstants.kelasMaster,
      queryParameters: {'active': activeOnly},
    );
    final list = (res.data as Map)['data'] as List;
    return list.map((e) => KelasMaster.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<KelasMaster> create({
    required String nama,
    required int cabangId,
    String? keterangan,
  }) async {
    final res = await _dio.post(ApiConstants.kelasMaster, data: {
      'nama': nama,
      'cabang_id': cabangId,
      if (keterangan != null) 'keterangan': keterangan,
      'is_active': true,
    });
    return KelasMaster.fromJson((res.data as Map)['data'] as Map<String, dynamic>);
  }

  Future<KelasMaster> update({
    required int id,
    required String nama,
    required int cabangId,
    String? keterangan,
    bool isActive = true,
  }) async {
    final res = await _dio.put(ApiConstants.kelasMasterDetail(id), data: {
      'nama': nama,
      'cabang_id': cabangId,
      if (keterangan != null) 'keterangan': keterangan,
      'is_active': isActive,
    });
    return KelasMaster.fromJson((res.data as Map)['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _dio.delete(ApiConstants.kelasMasterDetail(id));
  }
}

final kelasMasterRepositoryProvider =
    Provider((ref) => KelasMasterRepository(ref.read(dioProvider)));

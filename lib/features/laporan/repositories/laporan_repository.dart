import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/laporan_model.dart';

class LaporanRepository {
  final Dio _dio;

  const LaporanRepository(this._dio);

  Future<LaporanSummary> summary() async {
    final res = await _dio.get(ApiConstants.laporanSummary);
    return LaporanSummary.fromJson(res.data as Map<String, dynamic>);
  }

  Future<LaporanMatrix> matrix({String? from, String? to}) async {
    final res = await _dio.get(ApiConstants.laporanMatrix, queryParameters: {
      'from': from,
      'to': to,
    });
    return LaporanMatrix.fromJson(res.data as Map<String, dynamic>);
  }
}

final laporanRepositoryProvider = Provider((ref) => LaporanRepository(ref.read(dioProvider)));

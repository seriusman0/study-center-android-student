import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../laporan/models/laporan_model.dart';
import '../models/home_model.dart';

class HomeRepository {
  final Dio _dio;

  const HomeRepository(this._dio);

  Future<List<BlogPost>> fetchBlogs(String? cabangSlug) async {
    final res = await _dio.get(ApiConstants.blogs, queryParameters: {
      if (cabangSlug != null) 'cabang': cabangSlug,
      'sort': 'latest',
    });
    final data = res.data as Map<String, dynamic>;
    final items = (data['data'] as List? ?? []);
    return items.take(6).map((e) => BlogPost.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<GaleriItem>> fetchGaleri() async {
    final res = await _dio.get(ApiConstants.galeri);
    final data = res.data as Map<String, dynamic>;
    return (data['data'] as List? ?? [])
        .map((e) => GaleriItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LaporanSummary> fetchLaporan() async {
    final res = await _dio.get(ApiConstants.laporanSummary);
    return LaporanSummary.fromJson(res.data as Map<String, dynamic>);
  }
}

final homeRepositoryProvider = Provider((ref) => HomeRepository(ref.read(dioProvider)));

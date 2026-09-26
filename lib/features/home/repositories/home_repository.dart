import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../laporan/models/laporan_model.dart';
import '../models/home_model.dart';

class HomeRepository {
  final Dio _dio;

  const HomeRepository(this._dio);

  Future<File> _getCacheFile(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$name.json');
  }

  Future<List<BlogPost>> fetchBlogs(String? cabangSlug) async {
    final res = await _dio.get(ApiConstants.blogs, queryParameters: {
      if (cabangSlug != null) 'cabang': cabangSlug,
      'sort': 'latest',
    });
    final data = res.data as Map<String, dynamic>;
    final items = (data['data'] as List? ?? []);
    final mapped = items.take(6).map((e) => BlogPost.fromJson(e as Map<String, dynamic>)).toList();
    
    try {
      final file = await _getCacheFile('blogs_cache_$cabangSlug');
      await file.writeAsString(jsonEncode(mapped.map((e) => e.toJson()).toList()));
    } catch (_) {}

    return mapped;
  }

  Future<List<BlogPost>> getCachedBlogs(String? cabangSlug) async {
    try {
      final file = await _getCacheFile('blogs_cache_$cabangSlug');
      if (await file.exists()) {
        final content = await file.readAsString();
        final items = jsonDecode(content) as List;
        return items.map((e) => BlogPost.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<GaleriItem>> fetchGaleri() async {
    final res = await _dio.get(ApiConstants.galeri);
    final data = res.data as Map<String, dynamic>;
    final mapped = (data['data'] as List? ?? [])
        .map((e) => GaleriItem.fromJson(e as Map<String, dynamic>))
        .toList();

    try {
      final file = await _getCacheFile('galeri_cache');
      await file.writeAsString(jsonEncode(mapped.map((e) => e.toJson()).toList()));
    } catch (_) {}

    return mapped;
  }

  Future<List<GaleriItem>> getCachedGaleri() async {
    try {
      final file = await _getCacheFile('galeri_cache');
      if (await file.exists()) {
        final content = await file.readAsString();
        final items = jsonDecode(content) as List;
        return items.map((e) => GaleriItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<LaporanSummary> fetchLaporan() async {
    final res = await _dio.get(ApiConstants.laporanSummary);
    final laporan = LaporanSummary.fromJson(res.data as Map<String, dynamic>);

    try {
      final file = await _getCacheFile('laporan_cache');
      await file.writeAsString(jsonEncode(laporan.toJson()));
    } catch (_) {}

    return laporan;
  }

  Future<LaporanSummary?> getCachedLaporan() async {
    try {
      final file = await _getCacheFile('laporan_cache');
      if (await file.exists()) {
        final content = await file.readAsString();
        return LaporanSummary.fromJson(jsonDecode(content) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }
}

final homeRepositoryProvider = Provider((ref) => HomeRepository(ref.read(dioProvider)));

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/blog_model.dart';

class BlogRepository {
  final Dio _dio;

  const BlogRepository(this._dio);

  Future<BlogDetail> fetchDetail(String slug) async {
    final res = await _dio.get(ApiConstants.blogDetail(slug));
    final data = res.data as Map<String, dynamic>;
    // API may wrap in 'data' key or return directly
    final payload = data['data'] ?? data;
    return BlogDetail.fromJson(payload as Map<String, dynamic>);
  }

  Future<String> createBlog({
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    final res = await _dio.post(ApiConstants.blogs, data: {
      'title': title,
      'body': body,
      if (imageUrl != null) 'image': imageUrl,
    });
    final data = res.data as Map<String, dynamic>;
    final payload = data['data'] ?? data;
    return (payload as Map<String, dynamic>)['slug'] as String;
  }

  Future<String> uploadImage(String filePath) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post(ApiConstants.blogUploadImage, data: formData);
    final data = res.data as Map<String, dynamic>;
    return data['url'] as String;
  }

  Future<BlogComment> postComment({
    required int blogId,
    required String body,
  }) async {
    final res = await _dio.post(
      ApiConstants.blogComments(blogId),
      data: {'body': body},
    );
    final data = res.data as Map<String, dynamic>;
    final payload = data['data'] ?? data;
    return BlogComment.fromJson(payload as Map<String, dynamic>);
  }

  Future<void> deleteComment(int commentId) async {
    await _dio.delete(ApiConstants.deleteComment(commentId));
  }
}

final blogRepositoryProvider = Provider(
    (ref) => BlogRepository(ref.read(dioProvider)));

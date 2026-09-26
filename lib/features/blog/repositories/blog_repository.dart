import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/blog_model.dart';

class BlogRepository {
  final Dio _dio;

  const BlogRepository(this._dio);

  /// Fetches the blog detail AND its comments (two separate backend
  /// endpoints — GET /blogs/{slug} does not embed comments).
  Future<BlogDetail> fetchDetail(String slug) async {
    final res = await _dio.get(ApiConstants.blogDetail(slug));
    final data = res.data as Map<String, dynamic>;
    // API may wrap in 'data' key or return directly
    final payload = (data['data'] ?? data) as Map<String, dynamic>;
    final blog = BlogDetail.fromJson(payload);

    final blogId = payload['id'] as num?;
    if (blogId == null) return blog;

    final comments = await fetchComments(blogId.toInt());
    return blog.copyWithComments(comments);
  }

  Future<List<BlogComment>> fetchComments(int blogId) async {
    final res = await _dio.get(ApiConstants.blogComments(blogId));
    final data = res.data;
    final list = data is Map ? (data['data'] as List? ?? []) : (data as List? ?? []);
    return list.map((e) => BlogComment.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// [cabangId] is required by the backend (BlogController::store).
  Future<String> createBlog({
    required String title,
    required String body,
    required int cabangId,
    String? imageUrl,
  }) async {
    final res = await _dio.post(ApiConstants.blogs, data: {
      'title': title,
      // Backend field is `content`, not `body`.
      'content': body,
      'cabang_id': cabangId,
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
    int? parentId,
  }) async {
    final res = await _dio.post(
      ApiConstants.blogComments(blogId),
      // Backend field is `content`, not `body`.
      data: {'content': body, if (parentId != null) 'parent_id': parentId},
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

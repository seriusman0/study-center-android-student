import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/blog_moderation_model.dart';

class BlogModerationRepository {
  final Dio _dio;
  const BlogModerationRepository(this._dio);

  Future<List<AdminBlogModel>> fetchBlogs({String? search, int page = 1}) async {
    final response = await _dio.get(ApiConstants.adminBlogs, queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
    });
    final data = response.data as Map<String, dynamic>;
    final list = (data['data'] as List?) ?? [];
    return list.map((e) => AdminBlogModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteBlog(int id) async {
    await _dio.delete(ApiConstants.adminBlogDelete(id));
  }

  Future<List<AdminCommentModel>> fetchComments({int page = 1}) async {
    final response = await _dio.get(ApiConstants.adminComments, queryParameters: {'page': page});
    final data = response.data as Map<String, dynamic>;
    final list = (data['data'] as List?) ?? [];
    return list.map((e) => AdminCommentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteComment(int id) async {
    await _dio.delete(ApiConstants.adminCommentDelete(id));
  }
}

final blogModerationRepositoryProvider =
    Provider((ref) => BlogModerationRepository(ref.read(dioProvider)));

class BlogModerationState {
  final bool loadingBlogs;
  final bool loadingComments;
  final List<AdminBlogModel> blogs;
  final List<AdminCommentModel> comments;
  final String? blogsError;
  final String? commentsError;

  const BlogModerationState({
    this.loadingBlogs = false,
    this.loadingComments = false,
    this.blogs = const [],
    this.comments = const [],
    this.blogsError,
    this.commentsError,
  });

  BlogModerationState copyWith({
    bool? loadingBlogs,
    bool? loadingComments,
    List<AdminBlogModel>? blogs,
    List<AdminCommentModel>? comments,
    String? blogsError,
    String? commentsError,
  }) =>
      BlogModerationState(
        loadingBlogs: loadingBlogs ?? this.loadingBlogs,
        loadingComments: loadingComments ?? this.loadingComments,
        blogs: blogs ?? this.blogs,
        comments: comments ?? this.comments,
        blogsError: blogsError,
        commentsError: commentsError,
      );
}

class BlogModerationNotifier extends Notifier<BlogModerationState> {
  @override
  BlogModerationState build() => const BlogModerationState();

  Future<void> loadBlogs({String? search}) async {
    state = state.copyWith(loadingBlogs: true, blogsError: null);
    try {
      final blogs = await ref.read(blogModerationRepositoryProvider).fetchBlogs(search: search);
      state = state.copyWith(loadingBlogs: false, blogs: blogs);
    } catch (e) {
      state = state.copyWith(loadingBlogs: false, blogsError: extractErrorMessage(e));
    }
  }

  Future<void> loadComments() async {
    state = state.copyWith(loadingComments: true, commentsError: null);
    try {
      final comments = await ref.read(blogModerationRepositoryProvider).fetchComments();
      state = state.copyWith(loadingComments: false, comments: comments);
    } catch (e) {
      state = state.copyWith(loadingComments: false, commentsError: extractErrorMessage(e));
    }
  }

  Future<bool> deleteBlog(int id) async {
    try {
      await ref.read(blogModerationRepositoryProvider).deleteBlog(id);
      await loadBlogs();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteComment(int id) async {
    try {
      await ref.read(blogModerationRepositoryProvider).deleteComment(id);
      await loadComments();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final blogModerationProvider =
    NotifierProvider<BlogModerationNotifier, BlogModerationState>(BlogModerationNotifier.new);

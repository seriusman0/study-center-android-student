import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../models/blog_model.dart';
import '../repositories/blog_repository.dart';

// ---------------------------------------------------------------------------
// Blog Detail Provider
// ---------------------------------------------------------------------------
class BlogDetailState {
  final BlogDetail? blog;
  final bool loading;
  final String? error;
  final bool submittingComment;

  const BlogDetailState({
    this.blog,
    this.loading = false,
    this.error,
    this.submittingComment = false,
  });

  BlogDetailState copyWith({
    BlogDetail? blog,
    bool? loading,
    String? error,
    bool clearError = false,
    bool? submittingComment,
  }) =>
      BlogDetailState(
        blog:              blog             ?? this.blog,
        loading:           loading          ?? this.loading,
        error:             clearError ? null : (error ?? this.error),
        submittingComment: submittingComment ?? this.submittingComment,
      );
}

class BlogDetailNotifier
    extends AutoDisposeFamilyNotifier<BlogDetailState, String> {
  @override
  BlogDetailState build(String arg) {
    Future.microtask(load);
    return const BlogDetailState(loading: true);
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final blog =
          await ref.read(blogRepositoryProvider).fetchDetail(arg);
      state = BlogDetailState(blog: blog);
    } catch (e) {
      state = BlogDetailState(error: extractErrorMessage(e));
    }
  }

  Future<bool> postComment(String body) async {
    if (state.blog == null) return false;
    state = state.copyWith(submittingComment: true, clearError: true);
    try {
      final comment = await ref
          .read(blogRepositoryProvider)
          .postComment(blogId: state.blog!.id, body: body);
      final updatedComments = [...state.blog!.comments, comment];
      state = BlogDetailState(blog: state.blog!.copyWithComments(updatedComments));
      return true;
    } catch (e) {
      state = state.copyWith(
          submittingComment: false, error: extractErrorMessage(e));
      return false;
    }
  }

  Future<void> deleteComment(int commentId) async {
    try {
      await ref.read(blogRepositoryProvider).deleteComment(commentId);
      final updatedComments =
          state.blog!.comments.where((c) => c.id != commentId).toList();
      state = state.copyWith(blog: state.blog!.copyWithComments(updatedComments));
    } catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
    }
  }
}

final blogDetailProvider = NotifierProvider.autoDispose
    .family<BlogDetailNotifier, BlogDetailState, String>(
        BlogDetailNotifier.new);

// ---------------------------------------------------------------------------
// Blog Create Provider
// ---------------------------------------------------------------------------
class BlogCreateState {
  final bool loading;
  final String? error;
  final String? createdSlug;

  const BlogCreateState({
    this.loading = false,
    this.error,
    this.createdSlug,
  });

  BlogCreateState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    String? createdSlug,
  }) =>
      BlogCreateState(
        loading:     loading     ?? this.loading,
        error:       clearError ? null : (error ?? this.error),
        createdSlug: createdSlug ?? this.createdSlug,
      );
}

class BlogCreateNotifier
    extends AutoDisposeNotifier<BlogCreateState> {
  @override
  BlogCreateState build() => const BlogCreateState();

  Future<bool> create({
    required String title,
    required String body,
    required int cabangId,
    String? imageUrl,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final slug = await ref.read(blogRepositoryProvider).createBlog(
            title:    title,
            body:     body,
            cabangId: cabangId,
            imageUrl: imageUrl,
          );
      state = BlogCreateState(createdSlug: slug);
      return true;
    } catch (e) {
      state = BlogCreateState(error: extractErrorMessage(e));
      return false;
    }
  }
}

final blogCreateProvider =
    NotifierProvider.autoDispose<BlogCreateNotifier, BlogCreateState>(
        BlogCreateNotifier.new);

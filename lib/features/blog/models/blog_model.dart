class BlogDetail {
  final int id;
  final String title;
  final String slug;
  final String? image;
  final String? body;
  final String? publishedAt;
  final String? authorName;
  final String? authorAvatar;
  final String? cabangNama;
  final List<BlogComment> comments;

  const BlogDetail({
    required this.id,
    required this.title,
    required this.slug,
    this.image,
    this.body,
    this.publishedAt,
    this.authorName,
    this.authorAvatar,
    this.cabangNama,
    required this.comments,
  });

  factory BlogDetail.fromJson(Map<String, dynamic> j) {
    // Backend (BlogController::show) returns the author under the `user`
    // relation, not `author`. Comments arrive separately via
    // GET /blogs/{blog}/comments (CommentController::index), so `comments`
    // is optional here and populated by the repository/provider.
    final author = j['user'] as Map<String, dynamic>?;
    final commentsList = (j['comments'] as List? ?? [])
        .map((c) => BlogComment.fromJson(c as Map<String, dynamic>))
        .toList();
    return BlogDetail(
      id:           (j['id'] as num).toInt(),
      title:        j['title'] as String? ?? '',
      slug:         j['slug'] as String? ?? '',
      image:        j['image'] as String?,
      // Backend field is `content`, not `body`.
      body:         j['content'] as String?,
      publishedAt:  j['published_at'] as String?,
      authorName:   author?['name'] as String?,
      authorAvatar: author?['avatar'] as String?,
      cabangNama:   (j['cabang'] as Map?)?['nama'] as String?,
      comments:     commentsList,
    );
  }

  BlogDetail copyWithComments(List<BlogComment> newComments) => BlogDetail(
        id: id,
        title: title,
        slug: slug,
        image: image,
        body: body,
        publishedAt: publishedAt,
        authorName: authorName,
        authorAvatar: authorAvatar,
        cabangNama: cabangNama,
        comments: newComments,
      );
}

class BlogComment {
  final int id;
  final String body;
  final String authorName;
  final String? authorAvatar;
  final String? createdAt;
  final int? parentId;

  const BlogComment({
    required this.id,
    required this.body,
    required this.authorName,
    this.authorAvatar,
    this.createdAt,
    this.parentId,
  });

  factory BlogComment.fromJson(Map<String, dynamic> j) {
    // Backend (CommentController) returns author under `user`, and the
    // text field is `content`, not `body`.
    final author = j['user'] as Map<String, dynamic>? ?? {};
    return BlogComment(
      id:           (j['id'] as num).toInt(),
      body:         j['content'] as String? ?? '',
      authorName:   author['name'] as String? ?? 'Anonim',
      authorAvatar: author['avatar'] as String?,
      createdAt:    j['created_at'] as String?,
      parentId:     (j['parent_id'] as num?)?.toInt(),
    );
  }
}

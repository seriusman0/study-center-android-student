class AdminBlogModel {
  final int id;
  final String title;
  final String slug;
  final String? authorName;
  final String? authorUsername;
  final String? cabangNama;
  final String? publishedAt;
  final int commentsCount;

  const AdminBlogModel({
    required this.id,
    required this.title,
    required this.slug,
    this.authorName,
    this.authorUsername,
    this.cabangNama,
    this.publishedAt,
    this.commentsCount = 0,
  });

  factory AdminBlogModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final cabang = json['cabang'] as Map<String, dynamic>?;
    return AdminBlogModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      authorName: user?['name'] as String?,
      authorUsername: user?['username'] as String?,
      cabangNama: cabang?['nama'] as String?,
      publishedAt: json['published_at'] as String?,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminCommentModel {
  final int id;
  final String content;
  final String? userName;
  final String? userUsername;
  final String? blogTitle;
  final String? blogSlug;
  final String? createdAt;

  const AdminCommentModel({
    required this.id,
    required this.content,
    this.userName,
    this.userUsername,
    this.blogTitle,
    this.blogSlug,
    this.createdAt,
  });

  factory AdminCommentModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final blog = json['blog'] as Map<String, dynamic>?;
    return AdminCommentModel(
      id: (json['id'] as num).toInt(),
      content: json['content'] as String? ?? json['body'] as String? ?? '',
      userName: user?['name'] as String?,
      userUsername: user?['username'] as String?,
      blogTitle: blog?['title'] as String?,
      blogSlug: blog?['slug'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

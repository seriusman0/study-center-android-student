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
    final author = j['author'] as Map<String, dynamic>?;
    final commentsList = (j['comments'] as List? ?? [])
        .map((c) => BlogComment.fromJson(c as Map<String, dynamic>))
        .toList();
    return BlogDetail(
      id:           (j['id'] as num).toInt(),
      title:        j['title'] as String? ?? '',
      slug:         j['slug'] as String? ?? '',
      image:        j['image'] as String?,
      body:         j['body'] as String?,
      publishedAt:  j['published_at'] as String?,
      authorName:   author?['name'] as String?,
      authorAvatar: author?['avatar'] as String?,
      cabangNama:   (j['cabang'] as Map?)?['nama'] as String?,
      comments:     commentsList,
    );
  }
}

class BlogComment {
  final int id;
  final String body;
  final String authorName;
  final String? authorAvatar;
  final String? createdAt;

  const BlogComment({
    required this.id,
    required this.body,
    required this.authorName,
    this.authorAvatar,
    this.createdAt,
  });

  factory BlogComment.fromJson(Map<String, dynamic> j) {
    final author = j['author'] as Map<String, dynamic>? ?? {};
    return BlogComment(
      id:           (j['id'] as num).toInt(),
      body:         j['body'] as String? ?? '',
      authorName:   author['name'] as String? ?? 'Anonim',
      authorAvatar: author['avatar'] as String?,
      createdAt:    j['created_at'] as String?,
    );
  }
}

class BlogPost {
  final int id;
  final String title;
  final String slug;
  final String? image;
  final String? publishedAt;
  final String? cabangNama;

  const BlogPost({
    required this.id,
    required this.title,
    required this.slug,
    this.image,
    this.publishedAt,
    this.cabangNama,
  });

  factory BlogPost.fromJson(Map<String, dynamic> j) => BlogPost(
        id:         j['id'] as int,
        title:      j['title'] as String,
        slug:       j['slug'] as String,
        image:      j['image'] as String?,
        publishedAt: j['published_at'] as String?,
        cabangNama: (j['cabang'] as Map?)?['nama'] as String?,
      );
}

class GaleriItem {
  final int id;
  final String fotoUrl;
  final String tanggal;

  const GaleriItem({required this.id, required this.fotoUrl, required this.tanggal});

  factory GaleriItem.fromJson(Map<String, dynamic> j) => GaleriItem(
        id:       j['id'] as int,
        fotoUrl:  j['foto_url'] as String,
        tanggal:  j['tanggal'] as String,
      );
}

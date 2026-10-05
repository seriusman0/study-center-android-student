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

  factory BlogPost.fromJson(Map<String, dynamic> j) {
    String? imgUrl = j['image'] as String?;
    if (imgUrl != null && imgUrl.isNotEmpty && !imgUrl.startsWith('http')) {
      if (!imgUrl.startsWith('/')) imgUrl = '/$imgUrl';
      imgUrl = 'https://studycenter.nanoprojectdevindonesia.com$imgUrl';
    }
    return BlogPost(
      id:          (j['id'] as num).toInt(),
      title:       j['title'] as String? ?? '',
      slug:        j['slug'] as String? ?? '',
      image:       imgUrl,
      publishedAt: j['published_at'] as String?,
      cabangNama:  (j['cabang'] as Map?)?['nama'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'slug': slug,
        'image': image,
        'published_at': publishedAt,
        'cabang': cabangNama != null ? {'nama': cabangNama} : null,
      };
}

class GaleriItem {
  final int id;
  final String fotoUrl;
  final String tanggal;

  const GaleriItem({required this.id, required this.fotoUrl, required this.tanggal});

  factory GaleriItem.fromJson(Map<String, dynamic> j) {
    String fUrl = j['foto_url'] as String? ?? '';
    if (fUrl.isNotEmpty && !fUrl.startsWith('http')) {
      if (!fUrl.startsWith('/')) fUrl = '/$fUrl';
      fUrl = 'https://studycenter.nanoprojectdevindonesia.com$fUrl';
    }
    return GaleriItem(
      id:      (j['id'] as num).toInt(),
      fotoUrl: fUrl,
      tanggal: j['tanggal'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'foto_url': fotoUrl,
        'tanggal': tanggal,
      };
}

class MataPelajaranModel {
  final int id;
  final String nama;
  final int urutan;
  final bool isActive;

  const MataPelajaranModel({
    required this.id,
    required this.nama,
    this.urutan = 0,
    this.isActive = true,
  });

  factory MataPelajaranModel.fromJson(Map<String, dynamic> json) {
    return MataPelajaranModel(
      id: (json['id'] as num).toInt(),
      nama: json['nama'] as String? ?? '',
      urutan: (json['urutan'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

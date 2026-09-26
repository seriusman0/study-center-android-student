class KelasMaster {
  final int id;
  final String nama;
  final int cabangId;
  final String? cabang;
  final String? keterangan;
  final bool isActive;

  const KelasMaster({
    required this.id,
    required this.nama,
    required this.cabangId,
    this.cabang,
    this.keterangan,
    required this.isActive,
  });

  factory KelasMaster.fromJson(Map<String, dynamic> json) => KelasMaster(
        id: (json['id'] as num).toInt(),
        nama: json['nama'] as String? ?? '',
        cabangId: (json['cabang_id'] as num?)?.toInt() ?? 0,
        cabang: json['cabang'] as String?,
        keterangan: json['keterangan'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );
}

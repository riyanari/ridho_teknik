class LokasiModel {
  final String id;
  final String nama;
  final String alamat;
  final int jumlahAC;
  final DateTime lastService;

  LokasiModel({
    required this.id,
    required this.nama,
    required this.alamat,
    this.jumlahAC = 0,
    required this.lastService,
  });

  LokasiModel copyWith({
    String? id,
    String? nama,
    String? alamat,
    int? jumlahAC,
    DateTime? lastService,
  }) =>
      LokasiModel(
        id: id ?? this.id,
        nama: nama ?? this.nama,
        alamat: alamat ?? this.alamat,
        jumlahAC: jumlahAC ?? this.jumlahAC,
        lastService: lastService ?? this.lastService,
      );

  factory LokasiModel.fromJson(Map<String, dynamic> json) {
    return LokasiModel(
      id: (json['id']).toString(),
      nama: (json['nama'] ?? '').toString(),
      alamat: (json['alamat'] ?? '').toString(),
      jumlahAC: (json['jumlahAC'] ?? json['jumlah_ac'] ?? 0) is int
          ? (json['jumlahAC'] ?? json['jumlah_ac'] ?? 0) as int
          : int.tryParse((json['jumlahAC'] ?? json['jumlah_ac'] ?? '0').toString()) ?? 0,
      lastService: DateTime.tryParse((json['lastService'] ?? json['last_service'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'alamat': alamat,
      'jumlah_ac': jumlahAC,
      'last_service': lastService.toIso8601String(),
    };
  }
}

// lib/models/lokasi_model.dart
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
}
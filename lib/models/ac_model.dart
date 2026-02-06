import 'lokasi_model.dart';

class AcModel {
  final String id;
  final String lokasiId;
  final String nama;
  final String merk;
  final String type;
  final String kapasitas;
  final DateTime terakhirService;
  final LokasiModel? lokasi; // Tambahkan nested lokasi data

  AcModel({
    required this.id,
    required this.lokasiId,
    required this.nama,
    this.merk = 'Unknown',
    this.type = 'Standard',
    this.kapasitas = '1 PK',
    required this.terakhirService,
    this.lokasi,
  });

  factory AcModel.fromJson(Map<String, dynamic> json) {
    return AcModel(
      id: json['id'].toString(),
      lokasiId: json['location_id'].toString(),
      nama: json['name'] ?? '',
      merk: json['brand'] ?? 'Unknown',
      type: json['type'] ?? 'Standard',
      kapasitas: json['capacity'] ?? '1 PK',
      terakhirService: json['last_service'] != null
          ? DateTime.tryParse(json['last_service']) ?? DateTime.now()
          : DateTime.now(),
      lokasi: json['location'] != null
          ? LokasiModel.fromJson(json['location'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location_id': lokasiId,
      'name': nama,
      'brand': merk,
      'type': type,
      'capacity': kapasitas,
      'last_service': terakhirService.toIso8601String(),
      'location': lokasi?.toJson(),
    };
  }
}
// lib/models/ac_model.dart
class AcModel {
  final String id;
  final String lokasiId;
  final String nama;
  final String merk;
  final String type;
  final String kapasitas;
  final DateTime terakhirService;

  AcModel({
    required this.id,
    required this.lokasiId,
    required this.nama,
    this.merk = 'Unknown',
    this.type = 'Standard',
    this.kapasitas = '1 PK',
    required this.terakhirService,
  });
}
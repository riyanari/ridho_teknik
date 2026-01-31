// lib/models/servicer_model.dart
class ServicerModel {
  final String id;
  final String nama;
  final String spesialisasi;
  final String noHp;
  final double rating;
  final String foto;

  ServicerModel({
    required this.id,
    required this.nama,
    required this.spesialisasi,
    required this.noHp,
    this.rating = 0.0,
    required this.foto,
  });
}
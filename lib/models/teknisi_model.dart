// lib/models/teknisi_model.dart
class TeknisiModel {
  final String id;
  final String nama;
  final String spesialisasi;
  final String noHp;
  final double rating;
  final int totalService;
  final String foto;

  TeknisiModel({
    required this.id,
    required this.nama,
    required this.spesialisasi,
    required this.noHp,
    this.rating = 0.0,
    this.totalService = 0,
    required this.foto,
  });
}
import 'client_model.dart';

class LokasiModel {
  final String id;
  final String clientId; // Tambahkan clientId
  final String nama;
  final String alamat;
  final int jumlahAC;
  final DateTime lastService;
  final Client? client; // Tambahkan nested client data

  LokasiModel({
    required this.id,
    required this.clientId,
    required this.nama,
    required this.alamat,
    this.jumlahAC = 0,
    required this.lastService,
    this.client,
  });

  factory LokasiModel.fromJson(Map<String, dynamic> json) {
    return LokasiModel(
      id: json['id'].toString(),
      clientId: json['client_id'].toString(),
      nama: json['name'] ?? '',
      alamat: json['address'] ?? '',
      jumlahAC: json['jumlah_ac'] ?? json['ac_units_count'] ?? 0,
      lastService: json['last_service'] != null
          ? DateTime.tryParse(json['last_service']) ?? DateTime.now()
          : DateTime.now(),
      client: json['client'] != null
          ? Client.fromJson(json['client'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'name': nama,
      'address': alamat,
      'jumlah_ac': jumlahAC,
      'last_service': lastService.toIso8601String(),
      'client': client?.toJson(),
    };
  }
}
import 'package:ridho_teknik/models/user_model.dart';

class LokasiModel {
  final int id;
  final String nama;
  final String alamat;
  final int jumlahAC;
  final DateTime? lastService;

  final String? latitude;
  final String? longitude;
  final String? placeId;
  final String? gmapsUrl;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final int totalAcUnits;
  final List<UserModel> users;

  LokasiModel({
    required this.id,
    required this.nama,
    required this.alamat,
    this.jumlahAC = 0,
    this.lastService,
    this.latitude,
    this.longitude,
    this.placeId,
    this.gmapsUrl,
    this.createdAt,
    this.updatedAt,
    this.totalAcUnits = 0,
    this.users = const [],
  });

  int get totalAc => totalAcUnits > 0 ? totalAcUnits : jumlahAC;

  factory LokasiModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    return LokasiModel(
      id: parseInt(json['id']),
      nama: (json['name'] ?? '').toString(),
      alamat: (json['address'] ?? '').toString(),
      jumlahAC: parseInt(
        json['jumlah_ac'] ?? json['total_ac_units'] ?? json['ac_count'],
      ),
      lastService: parseDate(json['last_service']),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      placeId: json['place_id']?.toString(),
      gmapsUrl: json['gmaps_url']?.toString(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      totalAcUnits: parseInt(
        json['total_ac_units'] ?? json['ac_count'] ?? json['jumlah_ac'],
      ),
      users: json['users'] is List
          ? (json['users'] as List)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': nama,
      'address': alamat,
      'jumlah_ac': jumlahAC,
      'last_service': lastService?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'place_id': placeId,
      'gmaps_url': gmapsUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'total_ac_units': totalAcUnits,
      'users': users.map((user) => user.toJson()).toList(),
    };
  }
}
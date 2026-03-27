import 'room_model.dart';

class AcModel {
  final int id;
  final int roomId;
  final int locationId;

  final String nama;
  final String merk;
  final String type;
  final String kapasitas;

  final int lantai;

  final DateTime? terakhirService;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final RoomModel? room;

  AcModel({
    required this.id,
    required this.roomId,
    required this.locationId,
    required this.nama,
    required this.merk,
    required this.type,
    required this.kapasitas,
    required this.lantai,
    this.terakhirService,
    this.createdAt,
    this.updatedAt,
    this.room,
  });

  factory AcModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return AcModel(
      id: parseInt(json['id']),
      roomId: parseInt(json['room_id']),
      locationId: parseInt(json['location_id']),
      nama: (json['name'] ?? '').toString(),
      merk: (json['brand'] ?? 'Unknown').toString(),
      type: (json['type'] ?? '-').toString(),
      kapasitas: (json['capacity'] ?? '-').toString(),
      lantai: parseInt(json['lantai']),
      terakhirService: parseDate(json['last_service']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      room: json['room'] is Map<String, dynamic>
          ? RoomModel.fromJson(json['room'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'location_id': locationId,
      'name': nama,
      'brand': merk,
      'type': type,
      'capacity': kapasitas,
      'lantai': lantai,
      'last_service': terakhirService?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'room': room?.toJson(),
    };
  }
}
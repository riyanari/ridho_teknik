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

  String get lantaiLabel {
    return lantai > 0 ? 'Lantai $lantai' : '-';
  }

  factory AcModel.fromJson(
      Map<String, dynamic> json,
      ) {
    int parseInt(dynamic value) {
      if (value == null) {
        return 0;
      }

      if (value is int) {
        return value;
      }

      return int.tryParse(
        value.toString(),
      ) ??
          0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) {
        return null;
      }

      final text = value.toString().trim();

      if (text.isEmpty) {
        return null;
      }

      return DateTime.tryParse(text);
    }

    // ==========================================================
    // ROOM
    // ==========================================================

    Map<String, dynamic>? roomJson;

    if (json['room'] is Map) {
      roomJson = Map<String, dynamic>.from(
        json['room'] as Map,
      );
    }

    // ==========================================================
    // FLOOR
    // ==========================================================

    Map<String, dynamic>? floorJson;

    if (roomJson?['floor'] is Map) {
      floorJson = Map<String, dynamic>.from(
        roomJson!['floor'] as Map,
      );
    }

    // ==========================================================
    // LOCATION ID
    // ==========================================================
    //
    // PRIORITAS:
    //
    // 1. ac_units.location_id
    // 2. room.location_id
    // 3. room.location.id
    //
    // Ini penting karena pada sebagian data API:
    //
    // "location_id": null
    //
    // tetapi:
    //
    // room.location_id = 6
    //
    // ==========================================================

    int locationId = parseInt(
      json['location_id'],
    );

    if (locationId <= 0) {
      locationId = parseInt(
        roomJson?['location_id'],
      );
    }

    if (locationId <= 0) {
      final locationRaw =
      roomJson?['location'];

      if (locationRaw is Map) {
        locationId = parseInt(
          locationRaw['id'],
        );
      }
    }

    return AcModel(
      id: parseInt(
        json['id'],
      ),
      roomId: parseInt(
        json['room_id'] ??
            roomJson?['id'],
      ),
      locationId: locationId,
      nama: (json['name'] ?? '')
          .toString()
          .trim(),
      merk: (json['brand'] ?? 'Unknown')
          .toString()
          .trim(),
      type: (json['type'] ?? '-')
          .toString()
          .trim(),
      kapasitas: (json['capacity'] ?? '-')
          .toString()
          .trim(),
      lantai: parseInt(
        json['lantai'] ??
            floorJson?['number'],
      ),
      terakhirService: parseDate(
        json['last_service'],
      ),
      createdAt: parseDate(
        json['created_at'],
      ),
      updatedAt: parseDate(
        json['updated_at'],
      ),
      room: roomJson != null
          ? RoomModel.fromJson(
        roomJson,
      )
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
      'last_service':
      terakhirService?.toIso8601String(),
      'created_at':
      createdAt?.toIso8601String(),
      'updated_at':
      updatedAt?.toIso8601String(),
      'room': room?.toJson(),
    };
  }
}
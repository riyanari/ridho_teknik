import 'floor_simple_model.dart';

class RoomModel {
  final int id;
  final int floorId;
  final String name;
  final String? code;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int acUnitsCount;
  final FloorSimpleModel? floor;

  RoomModel({
    required this.id,
    required this.floorId,
    required this.name,
    this.code,
    this.createdAt,
    this.updatedAt,
    this.acUnitsCount = 0,
    this.floor,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final text = value.toString();
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    return RoomModel(
      id: parseInt(json['id']),
      floorId: parseInt(json['floor_id']),
      name: (json['name'] ?? '').toString(),
      code: json['code']?.toString(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      acUnitsCount: parseInt(json['ac_units_count']),
      floor: json['floor'] is Map<String, dynamic>
          ? FloorSimpleModel.fromJson(json['floor'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'floor_id': floorId,
      'name': name,
      'code': code,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'ac_units_count': acUnitsCount,
      'floor': floor?.toJson(),
    };
  }
}
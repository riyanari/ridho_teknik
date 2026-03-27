class FloorSimpleModel {
  final int id;
  final int locationId;
  final String name;
  final int number;

  FloorSimpleModel({
    required this.id,
    required this.locationId,
    required this.name,
    required this.number,
  });

  factory FloorSimpleModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return FloorSimpleModel(
      id: parseInt(json['id']),
      locationId: parseInt(json['location_id']),
      name: (json['name'] ?? '').toString(),
      number: parseInt(json['number']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location_id': locationId,
      'name': name,
      'number': number,
    };
  }
}
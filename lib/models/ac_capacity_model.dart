class AcCapacityModel {
  final int id;
  final String name;

  AcCapacityModel({
    required this.id,
    required this.name,
  });

  factory AcCapacityModel.fromJson(Map<String, dynamic> json) {
    return AcCapacityModel(
      id: json['id'] ?? 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}
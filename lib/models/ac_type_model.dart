class AcTypeModel {
  final int id;
  final String name;

  AcTypeModel({
    required this.id,
    required this.name,
  });

  factory AcTypeModel.fromJson(Map<String, dynamic> json) {
    return AcTypeModel(
      id: json['id'] ?? 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}
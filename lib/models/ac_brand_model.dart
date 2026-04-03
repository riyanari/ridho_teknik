class AcBrandModel {
  final int id;
  final String name;

  AcBrandModel({
    required this.id,
    required this.name,
  });

  factory AcBrandModel.fromJson(Map<String, dynamic> json) {
    return AcBrandModel(
      id: json['id'] ?? 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}
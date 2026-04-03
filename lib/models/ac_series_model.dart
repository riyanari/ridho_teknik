class AcSeriesModel {
  final int id;
  final String series;

  final int typeId;
  final int capacityId;

  final String? typeName;
  final String? capacityName;

  AcSeriesModel({
    required this.id,
    required this.series,
    required this.typeId,
    required this.capacityId,
    this.typeName,
    this.capacityName,
  });

  factory AcSeriesModel.fromJson(Map<String, dynamic> json) {
    return AcSeriesModel(
      id: json['id'] ?? 0,
      series: (json['series'] ?? '').toString(),
      typeId: json['type_id'] ?? 0,
      capacityId: json['capacity_id'] ?? 0,
      typeName: json['type']?['name'],
      capacityName: json['capacity']?['name'],
    );
  }
}
import 'ac_brand_model.dart';
import 'ac_capacity_model.dart';
import 'ac_series_model.dart';
import 'ac_type_model.dart';

class AcMasterFormOptionsModel {
  final List<AcBrandModel> brands;
  final List<AcTypeModel> types;
  final List<AcSeriesModel> series;
  final List<AcCapacityModel> capacities;

  AcMasterFormOptionsModel({
    required this.brands,
    required this.types,
    required this.series,
    required this.capacities,
  });

  factory AcMasterFormOptionsModel.fromJson(Map<String, dynamic> json) {
    return AcMasterFormOptionsModel(
      brands: (json['brands'] as List? ?? [])
          .map((e) => AcBrandModel.fromJson(e))
          .toList(),

      types: (json['types'] as List? ?? [])
          .map((e) => AcTypeModel.fromJson(e))
          .toList(),

      series: (json['series'] as List? ?? [])
          .map((e) => AcSeriesModel.fromJson(e))
          .toList(),

      capacities: (json['capacities'] as List? ?? [])
          .map((e) => AcCapacityModel.fromJson(e))
          .toList(),
    );
  }
}
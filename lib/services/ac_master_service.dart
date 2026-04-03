import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/ac_brand_model.dart';
import '../models/ac_capacity_model.dart';
import '../models/ac_series_model.dart';
import '../models/ac_type_model.dart';
import '../models/ac_master_form_options_model.dart';

class AcMasterService {
  final ApiClient api;

  AcMasterService({required this.api});

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  Future<List<AcBrandModel>> getBrands() async {
    try {
      final response = await api.get(ApiConfig.ownerAcMasterBrands);
      _log('🏷️ getBrands response: $response');

      final data = response['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(AcBrandModel.fromJson)
            .toList();
      }

      return <AcBrandModel>[];
    } catch (e) {
      throw Exception('Gagal mengambil data merk AC: $e');
    }
  }

  Future<List<AcTypeModel>> getTypes({int? brandId}) async {
    try {
      final response = await api.get(
        ApiConfig.ownerAcMasterTypes,
        query: brandId != null ? {'brand_id': brandId} : null,
      );

      _log('📦 getTypes response: $response');

      final data = response['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(AcTypeModel.fromJson)
            .toList();
      }

      return <AcTypeModel>[];
    } catch (e) {
      throw Exception('Gagal mengambil data tipe AC: $e');
    }
  }

  Future<List<AcSeriesModel>> getSeries({
    required int brandId,
    int? typeId,
  }) async {
    try {
      final response = await api.get(
        ApiConfig.ownerAcMasterSeries,
        query: {
          'brand_id': brandId,
          if (typeId != null) 'type_id': typeId,
        },
      );

      _log('🔢 getSeries response: $response');

      final data = response['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(AcSeriesModel.fromJson)
            .toList();
      }

      return <AcSeriesModel>[];
    } catch (e) {
      throw Exception('Gagal mengambil data seri AC: $e');
    }
  }

  Future<List<AcCapacityModel>> getCapacities({
    int? brandId,
    int? typeId,
  }) async {
    try {
      final response = await api.get(
        ApiConfig.ownerAcMasterCapacities,
        query: {
          if (brandId != null) 'brand_id': brandId,
          if (typeId != null) 'type_id': typeId,
        },
      );

      _log('⚡ getCapacities response: $response');

      final data = response['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(AcCapacityModel.fromJson)
            .toList();
      }

      return <AcCapacityModel>[];
    } catch (e) {
      throw Exception('Gagal mengambil data kapasitas AC: $e');
    }
  }

  Future<AcMasterFormOptionsModel> getFormOptions({
    int? brandId,
    int? typeId,
  }) async {
    try {
      final response = await api.get(
        ApiConfig.ownerAcMasterFormOptions,
        query: {
          if (brandId != null) 'brand_id': brandId,
          if (typeId != null) 'type_id': typeId,
        },
      );

      _log('🧩 getFormOptions response: $response');

      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return AcMasterFormOptionsModel.fromJson(data);
      }

      throw Exception('Format data master AC tidak valid');
    } catch (e) {
      throw Exception('Gagal mengambil opsi form AC: $e');
    }
  }
}
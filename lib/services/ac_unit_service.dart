import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/ac_model.dart';

class AcUnitService {
  final ApiClient api;

  AcUnitService({required this.api});

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  Map<String, dynamic>? _buildQuery({int? locationId}) {
    if (locationId == null) return null;

    return {
      'location_id': locationId,
    };
  }

  Future<List<AcModel>> getAcUnits({int? locationId}) async {
    try {
      final response = await api.get(
        ApiConfig.ownerAcUnits,
        query: _buildQuery(locationId: locationId),
      );

      _log('❄️ getAcUnits response: $response');

      final data = response['data'];

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>() // ✅ aman
            .map(AcModel.fromJson)
            .toList();
      }

      return <AcModel>[]; // fallback aman
    } catch (e) {
      throw Exception('Gagal mengambil data AC: $e');
    }
  }

  Future<AcModel> getAcUnitDetail(int id) async {
    try {
      final response = await api.get(
        ApiConfig.ownerAcUnitUpdate(id),
      );

      final data = response['data'];

      if (data is Map<String, dynamic>) {
        return AcModel.fromJson(data);
      }

      throw Exception('Format data AC tidak valid');
    } catch (e) {
      throw Exception('Gagal mengambil detail AC: $e');
    }
  }
}
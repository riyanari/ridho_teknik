import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/lokasi_model.dart';

class LocationService {
  final ApiClient api;

  LocationService({required this.api});

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  Map<String, dynamic> _buildQuery({
    int? userId,
  }) {
    final query = <String, dynamic>{};

    // Pakai key ini kalau backend ownerLocations memang filter by user_id
    if (userId != null) {
      query['user_id'] = userId;
    }

    return query;
  }

  Future<List<LokasiModel>> getLocations({
    int? userId,
  }) async {
    try {
      final query = _buildQuery(userId: userId);

      _log('📍 getLocations query=$query');

      final response = await api.get(
        ApiConfig.ownerLocations,
        query: query.isEmpty ? null : query,
      );

      final data = response['data'];

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(LokasiModel.fromJson)
            .toList();
      }

      return <LokasiModel>[];
    } catch (e) {
      throw Exception('Gagal mengambil data lokasi: $e');
    }
  }
}
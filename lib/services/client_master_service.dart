import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/ac_model.dart';
import '../models/lokasi_model.dart';

class ClientMasterService {
  ClientMasterService({required this.api});

  final ApiClient api;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  Future<List<LokasiModel>> getLokasi() async {
    _log('📍 ClientMasterService.getLokasi()');

    final json = await api.get(ApiConfig.clientLocations);
    final data = json['data'];

    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(LokasiModel.fromJson)
          .toList();
    }

    return <LokasiModel>[];
  }

  Future<List<AcModel>> getAc({int? locationId}) async {
    _log('❄️ ClientMasterService.getAc(locationId: $locationId)');

    final json = await api.get(
      ApiConfig.clientAcUnits,
      query: locationId == null ? null : {'location_id': locationId},
    );

    final data = json['data'];

    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(AcModel.fromJson)
          .toList();
    }

    return <AcModel>[];
  }
}
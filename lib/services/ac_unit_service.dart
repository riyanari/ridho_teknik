// services/ac_unit_service.dart
import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/ac_model.dart';

class AcUnitService {
  final ApiClient api;

  AcUnitService({required this.api});

  Future<List<AcModel>> getAcUnits({int? locationId}) async {
    try {
      final Map<String, dynamic> query = {};
      if (locationId != null) {
        query['location_id'] = locationId;
      }

      final response = await api.get(ApiConfig.ownerAcUnits, query: query);

      print('AC API Response (getAcUnits) owner: $response'); // Debug log

      if (response['data'] != null) {
        final acUnits = (response['data'] as List)
            .map((item) => AcModel.fromJson(item))
            .toList();
        return acUnits;
      } else {
        throw Exception('Data tidak ditemukan dalam response');
      }
    } catch (e) {
      print('Error in getAcUnits: $e');
      rethrow;
    }
  }

  Future<AcModel> getAcUnitDetail(int id) async {
    try {
      final response = await api.get(ApiConfig.ownerAcUnitUpdate(id));

      if (response['data'] != null) {
        return AcModel.fromJson(response['data']);
      } else {
        throw Exception('Data AC tidak ditemukan');
      }
    } catch (e) {
      print('Error in getAcUnitDetail: $e');
      rethrow;
    }
  }
}

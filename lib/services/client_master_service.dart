import '../api/api_client.dart';
import '../api/api_config.dart';

class ClientMasterService {
  ClientMasterService({required this.api});
  final ApiClient api;

  Future<List<Map<String, dynamic>>> getLokasi() async {
    final json = await api.get(ApiConfig.clientLocations);
    final data = (json['data'] as List?) ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getAc({int? locationId}) async {
    final json = await api.get(
      ApiConfig.clientAcUnits,
      query: locationId == null ? null : {'location_id': locationId},
    );
    final data = (json['data'] as List?) ?? [];
    return data.cast<Map<String, dynamic>>();
  }
}

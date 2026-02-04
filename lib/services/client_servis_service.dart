import '../api/api_client.dart';
import '../api/api_config.dart';

class ClientServisService {
  final ApiClient api;

  ClientServisService({required this.api});

  Future<List<Map<String, dynamic>>> getServis() async {
    final json = await api.get(ApiConfig.clientServisIndex);
    return (json['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<Map<String, dynamic>> getServisDetail(int id) async {
    return await api.get(ApiConfig.clientServisShow(id));
  }
}
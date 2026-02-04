import '../api/api_client.dart';
import '../api/api_config.dart';

class ClientKeluhanService {
  final ApiClient api;

  ClientKeluhanService({required this.api});

  Future<List<Map<String, dynamic>>> getKeluhan() async {
    final json = await api.get(ApiConfig.clientKeluhanIndex);
    return (json['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<Map<String, dynamic>> createKeluhan(Map<String, dynamic> body) async {
    return await api.post(ApiConfig.clientKeluhanStore, body: body);
  }
}
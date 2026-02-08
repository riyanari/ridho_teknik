// services/client_service.dart
import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/client_model.dart';

class ClientService {
  final ApiClient api;

  ClientService({required this.api});

  Future<List<Client>> getClients() async {
    try {
      final response = await api.get(ApiConfig.ownerClients);

      // Debug log
      print('Client API Response (getClients) owner: $response');

      if (response['data'] != null) {
        final clients = (response['data'] as List)
            .map((item) => Client.fromJson(item))
            .toList();
        return clients;
      } else {
        throw Exception('Data tidak ditemukan dalam response');
      }
    } catch (e) {
      print('Error in getClients: $e');
      rethrow;
    }
  }

  Future<Client> getClientDetail(int id) async {
    try {
      final response = await api.get('${ApiConfig.ownerClients}/$id');

      if (response['data'] != null) {
        return Client.fromJson(response['data']);
      } else {
        throw Exception('Data client tidak ditemukan');
      }
    } catch (e) {
      print('Error in getClientDetail: $e');
      rethrow;
    }
  }
}
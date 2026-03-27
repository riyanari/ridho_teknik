import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/client_model.dart';

class ClientService {
  final ApiClient api;

  ClientService({required this.api});

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  Future<List<Client>> getClients() async {
    try {
      final response = await api.get(ApiConfig.ownerClients);
      _log('👥 getClients response: $response');

      final data = response['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(Client.fromJson)
            .toList();
      }

      return <Client>[];
    } catch (e) {
      throw Exception('Gagal mengambil data client: $e');
    }
  }

  Future<Client> getClientDetail(int id) async {
    try {
      final response = await api.get(ApiConfig.ownerClientDetail(id));
      _log('👤 getClientDetail($id) response: $response');

      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return Client.fromJson(data);
      }

      throw Exception('Format data client tidak valid');
    } catch (e) {
      throw Exception('Gagal mengambil detail client: $e');
    }
  }
}
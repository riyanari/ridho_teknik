import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/technician_model.dart';

class TechnicianService {
  final ApiClient api;

  TechnicianService({required this.api});

  Future<List<Technician>> getTechnicians() async {
    try {
      final response = await api.get(ApiConfig.ownerTechnicians);

      final data = response['data'];

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>() // ✅ aman
            .map(Technician.fromJson)
            .toList();
      }

      return []; // fallback aman
    } catch (e) {
      throw Exception('Gagal mengambil teknisi: ${e.toString()}');
    }
  }
}
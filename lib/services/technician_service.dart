import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/technician_model.dart';

class TechnicianService {
  final ApiClient api;

  TechnicianService({required this.api});

  Future<List<Technician>> getTechnicians() async {
    try {
      final response = await api.get(ApiConfig.ownerTechnicians);

      // Debug log
      print('Technician API Response: $response');

      if (response['data'] != null) {
        final technicians = (response['data'] as List)
            .map((item) => Technician.fromJson(item))
            .toList();
        return technicians;
      } else {
        throw Exception('Data tidak ditemukan dalam response');
      }
    } catch (e) {
      print('Error in getTechnicians: $e');
      rethrow;
    }
  }

  // Future<Technician> getTechnicianDetail(int id) async {
  //   try {
  //     final response = await api.get('${ApiConfig.o}/$id');
  //
  //     if (response['data'] != null) {
  //       return Technician.fromJson(response['data']);
  //     } else {
  //       throw Exception('Data teknisi tidak ditemukan');
  //     }
  //   } catch (e) {
  //     print('Error in getTechnicianDetail: $e');
  //     rethrow;
  //   }
  // }
}

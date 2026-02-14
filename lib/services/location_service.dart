import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/lokasi_model.dart';

class LocationService {
  final ApiClient api;

  LocationService({required this.api});

  Future<List<LokasiModel>> getLocations({int? userId}) async {
    try {
      final Map<String, dynamic> query = {};

      // Gantilah client_id dengan user_id, dan hanya tambahkan jika userId ada
      if (userId != null) {
        query['user_id'] = userId;
      }

      final response = await api.get(ApiConfig.ownerLocations, query: query);

      print("userId LOK $userId");

      print('Location API Response: $response'); // Debug log

      if (response['data'] != null) {
        // Memparsing data lokasi
        final locations = (response['data'] as List)
            .map((item) => LokasiModel.fromJson(item))
            .toList();
        print("Parsed Locations: $locations");
        return locations;
      } else {
        throw Exception('Data tidak ditemukan dalam response');
      }
    } catch (e) {
      print('Error in getLocations: $e');
      rethrow;
    }
  }

// Future<LokasiModel> getLocationDetail(int id) async {
  //   try {
  //     final response = await api.get(ApiConfig.ownerLocations(id));
  //
  //     if (response['data'] != null) {
  //       return LokasiModel.fromJson(response['data']);
  //     } else {
  //       throw Exception('Data lokasi tidak ditemukan');
  //     }
  //   } catch (e) {
  //     print('Error in getLocationDetail: $e');
  //     rethrow;
  //   }
  // }
}
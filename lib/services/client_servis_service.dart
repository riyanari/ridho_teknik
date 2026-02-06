// DI services/client_servis_service.dart
import '../api/api_client.dart';
import '../api/api_config.dart';

class ClientServisService {
  final ApiClient api;

  ClientServisService({required this.api});

  Future<List<Map<String, dynamic>>> getServis({String? acId, String? lokasiId}) async {
    try {
      print('=== GET SERVIS API CALL ===');

      // Build query parameters
      final Map<String, dynamic> params = {};
      if (acId != null && acId.isNotEmpty) params['ac_id'] = acId;
      if (lokasiId != null && lokasiId.isNotEmpty) params['lokasi_id'] = lokasiId;

      print('Params: $params');

      // PERBAIKAN: Gunakan queryParams
      final json = await api.get(
        ApiConfig.clientServices,
        // queryParams: params.isNotEmpty ? params : null,
      );

      print('Response type: ${json.runtimeType}');
      print('Response keys: ${json.keys}');

      // PERBAIKAN: Handle struktur pagination
      return _extractDataFromResponse(json);

    } catch (e, stackTrace) {
      print('Error in getServis: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // PERBAIKAN: Metode untuk extract data dari berbagai struktur response
  List<Map<String, dynamic>> _extractDataFromResponse(Map<String, dynamic> response) {
    try {
      print('=== EXTRACTING DATA FROM RESPONSE ===');
      print('Response structure: $response');

      // Cek jika response memiliki 'data' field
      if (!response.containsKey('data')) {
        print('No data field in response');
        return [];
      }

      final dynamic dataField = response['data'];
      print('dataField type: ${dataField.runtimeType}');

      // PERBAIKAN: Jika dataField adalah Map (pagination structure)
      if (dataField is Map<String, dynamic>) {
        print('dataField is Map, keys: ${dataField.keys}');

        // Cek jika ada nested 'data' array di dalam map
        if (dataField.containsKey('data') && dataField['data'] is List) {
          final List<dynamic> dataList = dataField['data'] as List<dynamic>;
          print('Found data list with ${dataList.length} items');

          // Cast ke List<Map<String, dynamic>>
          final List<Map<String, dynamic>> result = [];
          for (var item in dataList) {
            if (item is Map<String, dynamic>) {
              result.add(item);
            } else {
              print('Warning: Item is not Map, type: ${item.runtimeType}');
            }
          }

          return result;
        }
        // Jika map langsung berisi data servis (tidak ada pagination)
        else if (dataField.containsKey('id')) {
          return [dataField];
        } else {
          print('Unexpected map structure: ${dataField.keys}');
          return [];
        }
      }
      // PERBAIKAN: Jika dataField langsung List (tidak ada pagination)
      else if (dataField is List) {
        print('dataField is List with ${dataField.length} items');

        final List<Map<String, dynamic>> result = [];
        for (var item in dataField) {
          if (item is Map<String, dynamic>) {
            result.add(item);
          } else {
            print('Warning: Item in list is not Map, type: ${item.runtimeType}');
          }
        }

        return result;
      }
      // Struktur tidak dikenali
      else {
        print('Unknown dataField type: ${dataField.runtimeType}');
        return [];
      }
    } catch (e) {
      print('Error extracting data: $e');
      return [];
    }
  }

// Future<Map<String, dynamic>> getServisDetail(int id) async {
//   return await api.get(ApiConfig.clientServices(id));
// }

  Future<Map<String, dynamic>> requestCuci({
    required int locationId,
    required bool semuaAc,
    List<int>? acUnits,
    String? catatan,
    String? tanggalBerkunjung,
  }) async {
    try {
      print('=== REQUEST CUCI API CALL ===');
      print('Location ID: $locationId');
      print('Semua AC: $semuaAc');
      print('AC Units: $acUnits');
      print('Catatan: $catatan');
      print('Tanggal Berkunjung: $tanggalBerkunjung');

      // Prepare request body
      final Map<String, dynamic> body = {
        'location_id': locationId,
        'semua_ac': semuaAc,
      };

      // Add ac_units only if not semuaAc and acUnits is not empty
      if (!semuaAc && acUnits != null && acUnits.isNotEmpty) {
        body['ac_units'] = acUnits;
      }

      // Add catatan if provided
      if (catatan != null && catatan.isNotEmpty) {
        body['catatan'] = catatan;
      }

      if (tanggalBerkunjung != null && tanggalBerkunjung.isNotEmpty) {
        body['tanggal_berkunjung'] = tanggalBerkunjung;
      }

      print('Request body: $body');

      // Make POST request
      final json = await api.post(
        ApiConfig.clientServiceCuci,
        body: body,
      );

      print('Response: $json');

      // Handle response
      if (json.containsKey('data')) {
        return json['data'] as Map<String, dynamic>;
      } else {
        return json;
      }
    } catch (e, stackTrace) {
      print('Error in requestCuci: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
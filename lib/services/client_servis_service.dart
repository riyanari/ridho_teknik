// DI services/client_servis_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:ridho_teknik/services/token_store.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';

class ClientServisService {
  final ApiClient api;
  final TokenStore store; // Tambahkan TokenStore

  ClientServisService({required this.api, required this.store}); // Ubah constructor

  Future<List<Map<String, dynamic>>> getServis({String? acId, String? lokasiId}) async {
    try {
      print('=== GET SERVIS API CALL CLIENT ===');

      // Build query parameters
      final Map<String, dynamic> params = {};
      if (acId != null && acId.isNotEmpty) params['ac_id'] = acId;
      if (lokasiId != null && lokasiId.isNotEmpty) params['lokasi_id'] = lokasiId;

      print('Params client: $params');

      final json = await api.get(
        ApiConfig.clientServices,
      );

      print('Response type client: ${json.runtimeType}');
      print('Response keys client: ${json.keys}');

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
      print('Response structure client: $response');

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

  Future<Map<String, dynamic>> requestPerbaikan({
    required int locationId,
    required int acUnitId,
    required String keluhan,
    required String priority,
    List<File>? fotoKeluhan,
    String? tanggalBerkunjung,
  }) async {
    try {
      print('=== REQUEST PERBAIKAN API CALL ===');
      print('Location ID: $locationId');
      print('AC Unit ID: $acUnitId');
      print('Keluhan: $keluhan');
      print('Priority: $priority');
      print('Foto Keluhan count: ${fotoKeluhan?.length ?? 0}');
      print('Tanggal Berkunjung: $tanggalBerkunjung');

      // Buat multipart request jika ada file foto
      if (fotoKeluhan != null && fotoKeluhan.isNotEmpty) {
        return await _requestPerbaikanWithFiles(
          locationId: locationId,
          acUnitId: acUnitId,
          keluhan: keluhan,
          priority: priority,
          fotoKeluhan: fotoKeluhan,
          tanggalBerkunjung: tanggalBerkunjung,
        );
      } else {
        // Request tanpa file (JSON biasa)
        final Map<String, dynamic> body = {
          'location_id': locationId,
          'ac_unit_id': acUnitId,
          'keluhan': keluhan,
          'priority': priority,
        };

        if (tanggalBerkunjung != null && tanggalBerkunjung.isNotEmpty) {
          body['tanggal_berkunjung'] = tanggalBerkunjung;
        }

        print('Request body (JSON): $body');

        final json = await api.post(
          ApiConfig.clientServicePerbaikan,
          body: body,
        );

        print('Response: $json');

        return _handleResponse(json);
      }
    } catch (e, stackTrace) {
      print('Error in requestPerbaikan: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Helper method untuk request dengan file upload
  Future<Map<String, dynamic>> _requestPerbaikanWithFiles({
    required int locationId,
    required int acUnitId,
    required String keluhan,
    required String priority,
    required List<File> fotoKeluhan,
    String? tanggalBerkunjung,
  }) async {
    try {
      print('=== REQUEST PERBAIKAN WITH FILES ===');

      // Buat multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.clientServicePerbaikan),
      );

      // Ambil token dari TokenStore (sama seperti ApiClient)
      final token = await store.getToken();
      print('Token retrieved from store: $token');

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      // PERBAIKAN: Gunakan format yang sama dengan ApiClient
      // ApiClient menggunakan token yang sudah termasuk "Bearer "
      // Jika token dari store sudah termasuk "Bearer ", gunakan langsung
      // Jika tidak, tambahkan "Bearer "
      final authHeader = token.startsWith('Bearer ') ? token : 'Bearer $token';

      // Add headers
      request.headers['Authorization'] = authHeader;
      request.headers['Accept'] = 'application/json';

      print('Authorization header: $authHeader');

      // Add text fields
      request.fields['location_id'] = locationId.toString();
      request.fields['ac_unit_id'] = acUnitId.toString();
      request.fields['keluhan'] = keluhan;
      request.fields['priority'] = priority;

      if (tanggalBerkunjung != null && tanggalBerkunjung.isNotEmpty) {
        request.fields['tanggal_berkunjung'] = tanggalBerkunjung;
      }

      // Add files
      for (int i = 0; i < fotoKeluhan.length; i++) {
        final file = fotoKeluhan[i];
        final fileStream = http.ByteStream(file.openRead());
        final length = await file.length();
        final multipartFile = http.MultipartFile(
          'foto_keluhan[$i]',
          fileStream,
          length,
          filename: 'keluhan_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        request.files.add(multipartFile);
      }

      // Debug: Print request details
      print('Request URL: ${request.url}');
      print('Request headers: ${request.headers}');
      print('Request fields: ${request.fields}');
      print('Number of files: ${request.files.length}');

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Handle response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        print('File upload response: $json');
        return _handleResponse(json);
      } else {
        final errorBody = response.body;
        final errorJson = jsonDecode(errorBody);
        final errorMessage = errorJson['message'] ?? errorBody;
        throw Exception('Failed to upload: ${response.statusCode} $errorMessage');
      }
    } catch (e, stackTrace) {
      print('Error in _requestPerbaikanWithFiles: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Helper method untuk handle response
  Map<String, dynamic> _handleResponse(Map<String, dynamic> response) {
    if (response.containsKey('data')) {
      return response['data'] as Map<String, dynamic>;
    }
    return response;
  }
}
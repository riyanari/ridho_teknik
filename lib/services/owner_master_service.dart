import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/ac_model.dart';
import '../models/lokasi_model.dart';
import '../models/servis_model.dart';
import '../models/user_model.dart';

class OwnerMasterService {
  final ApiClient api;

  OwnerMasterService({required this.api});

  // ===== HELPER METHODS =====

  List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data == null) return [];
    if (data is List) {
      return data
          .where((item) => item is Map<String, dynamic>)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  T _parseSingle<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data is Map<String, dynamic>) {
      return fromJson(data);
    }
    throw Exception('Format data tidak valid');
  }

  // ===== CLIENT MANAGEMENT =====
  Future<List<UserModel>> getClients({
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      print('🔍 OwnerMasterService.getClients() - Memanggil API');
      final Map<String, dynamic> query = {};
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (sortBy != null) query['sort_by'] = sortBy;
      if (sortOrder != null) query['sort_order'] = sortOrder;

      print('   Query parameters: $query');
      final response = await api.get(ApiConfig.ownerClients, query: query);
      print('   Response received: ${response.containsKey('data')}');

      final data = response['data'] as List? ?? [];
      print('   Data length: ${data.length}');

      if (data.isNotEmpty) {
        print('   Data sample pertama:');
        print('     ${jsonEncode(data.first)}');
      }

      final result = _parseList(data, UserModel.fromJson);
      print('   Parsed ${result.length} clients');
      return result;
    } catch (e) {
      print('❌ Error in getClients: $e');
      rethrow;
    }
  }

  Future<UserModel> getClientDetail(int id) async {
    try {
      print('🔍 OwnerMasterService.getClientDetail($id) - Memanggil API');
      final response = await api.get(ApiConfig.ownerClientDetail(id));
      print('   Response: ${response.containsKey('data')}');
      return _parseSingle(response['data'], UserModel.fromJson);
    } catch (e) {
      print('❌ Error in getClientDetail: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getClientStats(int id) async {
    try {
      print('📊 OwnerMasterService.getClientStats($id) - Memanggil API');
      final response = await api.get(ApiConfig.ownerClientStats(id));
      print('   Response: ${response['data']}');
      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error in getClientStats: $e');
      rethrow;
    }
  }

  Future<UserModel> createClient(Map<String, dynamic> data) async {
    try {
      print('➕ OwnerMasterService.createClient() - Memanggil API');
      final response = await api.post(
        ApiConfig.ownerClientStore,
        body: data,
      );
      print('   Response received');
      return _parseSingle(response['data'], UserModel.fromJson);
    } catch (e) {
      print('❌ Error in createClient: $e');
      rethrow;
    }
  }

  Future<UserModel> updateClient(int id, Map<String, dynamic> data) async {
    try {
      print('✏️ OwnerMasterService.updateClient($id) - Memanggil API');
      final response = await api.put(
        ApiConfig.ownerClientUpdate(id),
        body: data,
      );
      print('   Response received');
      return _parseSingle(response['data'], UserModel.fromJson);
    } catch (e) {
      print('❌ Error in updateClient: $e');
      rethrow;
    }
  }

  Future<bool> deleteClient(int id) async {
    try {
      print('🗑️ OwnerMasterService.deleteClient($id) - Memanggil API');
      await api.delete(ApiConfig.ownerClientDestroy(id));
      print('   Delete successful');
      return true;
    } catch (e) {
      print('❌ Error in deleteClient: $e');
      rethrow;
    }
  }

  // ===== TECHNICIAN MANAGEMENT =====
  Future<List<UserModel>> getTechnicians({
    String? search,
    String? spesialisasi,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      print('🔧 OwnerMasterService.getTechnicians() - Memanggil API');
      final Map<String, dynamic> query = {};
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (spesialisasi != null) query['spesialisasi'] = spesialisasi;
      if (sortBy != null) query['sort_by'] = sortBy;
      if (sortOrder != null) query['sort_order'] = sortOrder;

      print('   Query parameters: $query');
      final response = await api.get(ApiConfig.ownerTechnicians, query: query);
      print('   Response received: ${response.containsKey('data')}');

      final data = response['data'] as List? ?? [];
      print('   Data length: ${data.length}');

      if (data.isNotEmpty) {
        print('   Data sample pertama:');
        print('     ${jsonEncode(data.first)}');
      }

      final result = _parseList(data, UserModel.fromJson);
      print('   Parsed ${result.length} technicians');
      return result;
    } catch (e) {
      print('❌ Error in getTechnicians: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> getAvailableTechnicians() async {
    try {
      print('🔧 OwnerMasterService.getAvailableTechnicians() - Memanggil API');
      final response = await api.get(ApiConfig.ownerAvailableTechnicians);
      print('   Response received: ${response.containsKey('data')}');
      final data = response['data'] as List? ?? [];
      print('   Data length: ${data.length}');
      return _parseList(data, UserModel.fromJson);
    } catch (e) {
      print('❌ Error in getAvailableTechnicians: $e');
      rethrow;
    }
  }

  Future<UserModel> getTechnicianDetail(int id) async {
    try {
      print('🔍 OwnerMasterService.getTechnicianDetail($id) - Memanggil API');
      final response = await api.get(ApiConfig.ownerTechnicianDetail(id));
      print('   Response received');
      return _parseSingle(response['data'], UserModel.fromJson);
    } catch (e) {
      print('❌ Error in getTechnicianDetail: $e');
      rethrow;
    }
  }

  Future<UserModel> createTechnician(Map<String, dynamic> data) async {
    try {
      print('➕ OwnerMasterService.createTechnician() - Memanggil API');
      final response = await api.post(
        ApiConfig.ownerTechnicianStore,
        body: data,
      );
      print('   Response received');
      return _parseSingle(response['data'], UserModel.fromJson);
    } catch (e) {
      print('❌ Error in createTechnician: $e');
      rethrow;
    }
  }

  Future<UserModel> updateTechnician(int id, Map<String, dynamic> data) async {
    try {
      print('✏️ OwnerMasterService.updateTechnician($id) - Memanggil API');
      final response = await api.put(
        ApiConfig.ownerTechnicianUpdate(id),
        body: data,
      );
      print('   Response received');
      return _parseSingle(response['data'], UserModel.fromJson);
    } catch (e) {
      print('❌ Error in updateTechnician: $e');
      rethrow;
    }
  }

  Future<bool> deleteTechnician(int id) async {
    try {
      print('🗑️ OwnerMasterService.deleteTechnician($id) - Memanggil API');
      await api.delete(ApiConfig.ownerTechnicianDestroy(id));
      print('   Delete successful');
      return true;
    } catch (e) {
      print('❌ Error in deleteTechnician: $e');
      rethrow;
    }
  }

  // ===== LOCATION MANAGEMENT =====
  Future<List<LokasiModel>> getLocations({
    String? search,
    int? clientId,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      print('📍 OwnerMasterService.getLocations() - Memanggil API');
      final Map<String, dynamic> query = {};
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (clientId != null) query['client_id'] = clientId;
      if (sortBy != null) query['sort_by'] = sortBy;
      if (sortOrder != null) query['sort_order'] = sortOrder;

      print('   Query parameters: $query');
      final response = await api.get(ApiConfig.ownerLocations, query: query);
      print('   Response received: ${response.containsKey('data')}');

      final data = response['data'] as List? ?? [];
      print('   Data length: ${data.length}');

      if (data.isNotEmpty) {
        print('   Data sample pertama:');
        print('     ${jsonEncode(data.first)}');
      }

      final result = _parseList(data, LokasiModel.fromJson);
      print('   Parsed ${result.length} locations');
      return result;
    } catch (e) {
      print('❌ Error in getLocations: $e');
      rethrow;
    }
  }

  Future<LokasiModel> createLocation(Map<String, dynamic> data) async {
    try {
      print('➕ OwnerMasterService.createLocation() - Memanggil API');
      final response = await api.post(
        ApiConfig.ownerLocationStore,
        body: data,
      );
      print('   Response received');
      return _parseSingle(response['data'], LokasiModel.fromJson);
    } catch (e) {
      print('❌ Error in createLocation: $e');
      rethrow;
    }
  }

  Future<LokasiModel> updateLocation(int id, Map<String, dynamic> data) async {
    try {
      print('✏️ OwnerMasterService.updateLocation($id) - Memanggil API');
      final response = await api.put(
        ApiConfig.ownerLocationUpdate(id),
        body: data,
      );
      print('   Response received');
      return _parseSingle(response['data'], LokasiModel.fromJson);
    } catch (e) {
      print('❌ Error in updateLocation: $e');
      rethrow;
    }
  }

  Future<bool> deleteLocation(int id) async {
    try {
      print('🗑️ OwnerMasterService.deleteLocation($id) - Memanggil API');
      await api.delete(ApiConfig.ownerLocationDestroy(id));
      print('   Delete successful');
      return true;
    } catch (e) {
      print('❌ Error in deleteLocation: $e');
      rethrow;
    }
  }

  // ===== AC UNIT MANAGEMENT =====
  Future<List<AcModel>> getAcUnits({
    int? locationId,
    int? clientId,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      print('❄️ OwnerMasterService.getAcUnits() - Memanggil API');
      final Map<String, dynamic> query = {};
      if (locationId != null) query['location_id'] = locationId;
      if (clientId != null) query['client_id'] = clientId;
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (sortBy != null) query['sort_by'] = sortBy;
      if (sortOrder != null) query['sort_order'] = sortOrder;

      print('   Query parameters: $query');
      final response = await api.get(ApiConfig.ownerAcUnits, query: query);
      print('   Response received: ${response.containsKey('data')}');

      final data = response['data'] as List? ?? [];
      print('   Data length: ${data.length}');

      if (data.isNotEmpty) {
        print('   Data sample pertama:');
        print('     ${jsonEncode(data.first)}');
      }

      final result = _parseList(data, AcModel.fromJson);
      print('   Parsed ${result.length} AC units');
      return result;
    } catch (e) {
      print('❌ Error in getAcUnits: $e');
      rethrow;
    }
  }

  Future<AcModel> getAcUnitDetail(int id) async {
    try {
      print('🔍 OwnerMasterService.getAcUnitDetail($id) - Memanggil API');
      final response = await api.get(ApiConfig.ownerAcUnitDetail(id));
      print('   Response received');
      return _parseSingle(response['data'], AcModel.fromJson);
    } catch (e) {
      print('❌ Error in getAcUnitDetail: $e');
      rethrow;
    }
  }

  Future<AcModel> createAcUnit(Map<String, dynamic> data) async {
    try {
      print('➕ OwnerMasterService.createAcUnit() - Memanggil API');
      final response = await api.post(
        ApiConfig.ownerAcUnitStore,
        body: data,
      );
      print('   Response received');
      return _parseSingle(response['data'], AcModel.fromJson);
    } catch (e) {
      print('❌ Error in createAcUnit: $e');
      rethrow;
    }
  }

  Future<AcModel> updateAcUnit(int id, Map<String, dynamic> data) async {
    try {
      print('✏️ OwnerMasterService.updateAcUnit($id) - Memanggil API');
      final response = await api.put(
        ApiConfig.ownerAcUnitUpdate(id),
        body: data,
      );
      print('   Response received');
      return _parseSingle(response['data'], AcModel.fromJson);
    } catch (e) {
      print('❌ Error in updateAcUnit: $e');
      rethrow;
    }
  }

  Future<bool> deleteAcUnit(int id) async {
    try {
      print('🗑️ OwnerMasterService.deleteAcUnit($id) - Memanggil API');
      await api.delete(ApiConfig.ownerAcUnitDestroy(id));
      print('   Delete successful');
      return true;
    } catch (e) {
      print('❌ Error in deleteAcUnit: $e');
      rethrow;
    }
  }

  // ===== SERVICE MANAGEMENT =====
  Future<List<ServisModel>> getServices({Map<String, dynamic>? query}) async {
    try {
      print('📅 OwnerMasterService.getServices() - Memanggil API');
      final q = query ?? {};

      print('   Query parameters: $q');
      final response = await api.get(ApiConfig.ownerServices, query: q);

      final data = response['data'] as List? ?? [];
      final result = _parseList(data, ServisModel.fromMap);
      print('   Parsed ${result.length} services');
      return result;
    } catch (e) {
      print('❌ Error in getServices: $e');
      rethrow;
    }
  }


  Future<ServisModel> getServiceDetail(int id) async {
    try {
      print('🔍 OwnerMasterService.getServiceDetail($id) - Memanggil API');
      final response = await api.get(ApiConfig.ownerServiceDetail(id));
      print('   Response received');
      return _parseSingle(response['data'], ServisModel.fromMap);
    } catch (e) {
      print('❌ Error in getServiceDetail: $e');
      rethrow;
    }
  }

  Future<ServisModel> updateService(int id, Map<String, dynamic> data) async {
    try {
      print('✏️ OwnerMasterService.updateService($id) - Memanggil API');
      final response = await api.put(
        ApiConfig.ownerServiceUpdate(id),
        body: data,
      );
      print('   Response received');
      return _parseSingle(response['data'], ServisModel.fromMap);
    } catch (e) {
      print('❌ Error in updateService: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> confirmServiceRequest(int id) async {
    try {
      print('✅ OwnerMasterService.confirmServiceRequest($id) - Memanggil API');
      final response = await api.post(
        ApiConfig.ownerServiceConfirmRequest(id),
      );
      print('   Response received');
      return response;
    } catch (e) {
      print('❌ Error in confirmServiceRequest: $e');
      rethrow;
    }
  }

  // HAPUS method ini dari ServiceListPage
  Future<Map<String, dynamic>> assignTechnician(int id, int technicianId) async {
    try {
      print('👨‍🔧 OwnerMasterService.assignTechnician($id, $technicianId) - Memanggil API');

      // PERBAIKAN: Untuk single technician, tetap kirim sebagai array dengan 1 item
      final body = {
        'technician_ids': [technicianId], // Kirim sebagai array dengan 1 item
      };

      print('   Endpoint: ${ApiConfig.ownerServiceAssignTechnician(id)}');
      print('   Request body: $body');

      final response = await api.post(
        ApiConfig.ownerServiceAssignTechnician(id),
        body: body,
      );

      print('   Response received');
      print('   Response status: ${response['success']}');
      print('   Response message: ${response['message']}');

      return response;
    } catch (e) {
      print('❌ Error in assignTechnician: $e');
      rethrow;
    }
  }

  // ===== MULTIPLE TECHNICIANS ASSIGNMENT =====

  // ===== MULTIPLE TECHNICIANS ASSIGNMENT =====
  Future<Map<String, dynamic>> assignMultipleTechnicians(
      int serviceId,
      List<int> technicianIds, {
        DateTime? tanggalDitugaskan,
      }) async {
    final body = <String, dynamic>{
      'technician_ids': technicianIds,
      if (tanggalDitugaskan != null)
        'tanggal_ditugaskan': DateFormat('yyyy-MM-dd HH:mm:ss').format(tanggalDitugaskan),
    };

    print("===== assignMultipleTechnicians service =====");
    print("serviceId: $serviceId");
    print("technicianIds: $technicianIds");
    print("tanggalDitugaskan: $tanggalDitugaskan");
    print("body: $body");

    final res = await api.post(
      ApiConfig.ownerServiceAssignMultipleTechnicians(serviceId),
      body: body,
    );

    print("✅ Response assignMultipleTechnicians:");
    print(res); // kalau Map, ini cukup
    // Kalau mau lebih rapi:
    // print(const JsonEncoder.withIndent('  ').convert(res));

    return res;
  }


// Untuk reassign, bisa gunakan method yang sama
  Future<Map<String, dynamic>> reassignTechnician(int id, List<int> technicianIds) async {
    return await assignMultipleTechnicians(id, technicianIds); // ✅ no date
  }


  Future<Map<String, dynamic>> confirmWork(int id) async {
    try {
      print('✅ OwnerMasterService.confirmWork($id) - Memanggil API');
      final response = await api.post(
        ApiConfig.ownerServiceConfirmWork(id),
      );
      print('   Response received');
      return response;
    } catch (e) {
      print('❌ Error in confirmWork: $e');
      rethrow;
    }
  }

  // ===== DASHBOARD & REPORTS =====
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      print('📈 OwnerMasterService.getDashboardStats() - Memanggil API');
      final response = await api.get(ApiConfig.ownerDashboardStats);
      print('   Response received: ${response.containsKey('data')}');

      final data = response['data'] as Map<String, dynamic>? ?? {};
      print('   Dashboard stats:');
      data.forEach((key, value) {
        print('     $key: $value');
      });

      return data;
    } catch (e) {
      print('❌ Error in getDashboardStats: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFilterOptions() async {
    try {
      print('🔧 OwnerMasterService.getFilterOptions() - Memanggil API');
      final response = await api.get(ApiConfig.ownerFilterOptions);
      print('   Response received: ${response.containsKey('data')}');
      final data = response['data'] as Map<String, dynamic>? ?? {};
      print('   Filter options keys: ${data.keys.toList()}');
      return data;
    } catch (e) {
      print('❌ Error in getFilterOptions: $e');
      rethrow;
    }
  }

  Future<String> exportServices({
    String? status,
    int? clientId,
    int? locationId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      print('📤 OwnerMasterService.exportServices() - Memanggil API');
      final Map<String, dynamic> query = {};
      if (status != null) query['status'] = status;
      if (clientId != null) query['client_id'] = clientId;
      if (locationId != null) query['location_id'] = locationId;
      if (type != null) query['type'] = type;
      if (startDate != null) query['start_date'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) query['end_date'] = endDate.toIso8601String().split('T')[0];

      print('   Query parameters: $query');
      final response = await api.get(
        ApiConfig.ownerExport,
        query: query,
      );
      print('   Response received: ${response.containsKey('data')}');
      final downloadUrl = response['data']['download_url'] as String? ?? '';
      print('   Download URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error in exportServices: $e');
      rethrow;
    }
  }

  // Di OwnerMasterService
  Future<ServisModel> updateServiceStatus(int id, String status) async {
    try {
      print('🔄 OwnerMasterService.updateServiceStatus($id, $status) - Memanggil API');
      final response = await api.put(
        ApiConfig.ownerServiceUpdate(id),
        body: {'status': status},
      );
      print('   Response received');
      return _parseSingle(response['data'], ServisModel.fromMap);
    } catch (e) {
      print('❌ Error in updateServiceStatus: $e');
      rethrow;
    }
  }
}

// ClientMasterService (untuk perbandingan)
class ClientMasterService {
  ClientMasterService({required this.api});
  final ApiClient api;

  Future<List<Map<String, dynamic>>> getLokasi() async {
    try {
      print('📍 ClientMasterService.getLokasi() - Memanggil API');
      final json = await api.get(ApiConfig.clientLocations);
      print('   Response received: ${json.containsKey('data')}');
      final data = (json['data'] as List?) ?? [];
      print('   Data length: ${data.length}');
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error in ClientMasterService.getLokasi: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAc({int? locationId}) async {
    try {
      print('❄️ ClientMasterService.getAc() - Memanggil API');
      final json = await api.get(
        ApiConfig.clientAcUnits,
        query: locationId == null ? null : {'location_id': locationId},
      );
      print('   Response received: ${json.containsKey('data')}');
      final data = (json['data'] as List?) ?? [];
      print('   Data length: ${data.length}');
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error in ClientMasterService.getAc: $e');
      rethrow;
    }
  }
}
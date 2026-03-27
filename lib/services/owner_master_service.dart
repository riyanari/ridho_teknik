import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/ac_model.dart';
import '../models/lokasi_model.dart';
import '../models/room_model.dart';
import '../models/servis_model.dart';
import '../models/user_model.dart';

class OwnerMasterService {
  final ApiClient api;

  OwnerMasterService({required this.api});

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  List<T> _parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is! List) return <T>[];

    return data.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }

  T _parseSingle<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data is Map<String, dynamic>) {
      return fromJson(data);
    }
    throw Exception('Format data tidak valid');
  }

  Map<String, dynamic> _cleanQuery(Map<String, dynamic> query) {
    final result = <String, dynamic>{};
    query.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      result[key] = value;
    });
    return result;
  }

  // =========================
  // CLIENT
  // =========================

  Future<List<UserModel>> getClients({
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    final query = _cleanQuery({
      'search': search,
      'sort_by': sortBy,
      'sort_order': sortOrder,
    });

    _log('🔍 getClients query=$query');

    final response = await api.get(ApiConfig.ownerClients, query: query);
    return _parseList(response['data'], UserModel.fromJson);
  }

  Future<UserModel> getClientDetail(int id) async {
    _log('🔍 getClientDetail($id)');
    final response = await api.get(ApiConfig.ownerClientDetail(id));
    return _parseSingle(response['data'], UserModel.fromJson);
  }

  Future<Map<String, dynamic>> getClientStats(int id) async {
    _log('📊 getClientStats($id)');
    final response = await api.get(ApiConfig.ownerClientStats(id));
    return (response['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  Future<UserModel> createClient(Map<String, dynamic> data) async {
    _log('➕ createClient');
    final response = await api.post(ApiConfig.ownerClientStore, body: data);
    return _parseSingle(response['data'], UserModel.fromJson);
  }

  Future<UserModel> updateClient(int id, Map<String, dynamic> data) async {
    _log('✏️ updateClient($id)');
    final response = await api.put(ApiConfig.ownerClientUpdate(id), body: data);
    return _parseSingle(response['data'], UserModel.fromJson);
  }

  Future<bool> deleteClient(int id) async {
    _log('🗑️ deleteClient($id)');
    await api.delete(ApiConfig.ownerClientDestroy(id));
    return true;
  }

  // =========================
  // TECHNICIAN
  // =========================

  Future<List<UserModel>> getTechnicians({
    String? search,
    String? spesialisasi,
    String? sortBy,
    String? sortOrder,
  }) async {
    final query = _cleanQuery({
      'search': search,
      'spesialisasi': spesialisasi,
      'sort_by': sortBy,
      'sort_order': sortOrder,
    });

    _log('🔧 getTechnicians query=$query');

    final response = await api.get(ApiConfig.ownerTechnicians, query: query);
    return _parseList(response['data'], UserModel.fromJson);
  }

  Future<List<UserModel>> getAvailableTechnicians() async {
    _log('🔧 getAvailableTechnicians');
    final response = await api.get(ApiConfig.ownerAvailableTechnicians);
    return _parseList(response['data'], UserModel.fromJson);
  }

  Future<UserModel> getTechnicianDetail(int id) async {
    _log('🔍 getTechnicianDetail($id)');
    final response = await api.get(ApiConfig.ownerTechnicianDetail(id));
    return _parseSingle(response['data'], UserModel.fromJson);
  }

  Future<UserModel> createTechnician(Map<String, dynamic> data) async {
    _log('➕ createTechnician');
    final response = await api.post(ApiConfig.ownerTechnicianStore, body: data);
    return _parseSingle(response['data'], UserModel.fromJson);
  }

  Future<UserModel> updateTechnician(int id, Map<String, dynamic> data) async {
    _log('✏️ updateTechnician($id)');
    final response = await api.put(
      ApiConfig.ownerTechnicianUpdate(id),
      body: data,
    );
    return _parseSingle(response['data'], UserModel.fromJson);
  }

  Future<bool> deleteTechnician(int id) async {
    _log('🗑️ deleteTechnician($id)');
    await api.delete(ApiConfig.ownerTechnicianDestroy(id));
    return true;
  }

  // =========================
  // LOCATION
  // =========================

  Future<List<LokasiModel>> getLocations({
    String? search,
    int? clientId,
    String? sortBy,
    String? sortOrder,
  }) async {
    final query = _cleanQuery({
      'search': search,
      'client_id': clientId,
      'sort_by': sortBy,
      'sort_order': sortOrder,
    });

    _log('📍 getLocations query=$query');

    final response = await api.get(ApiConfig.ownerLocations, query: query);
    return _parseList(response['data'], LokasiModel.fromJson);
  }

  Future<LokasiModel> createLocation(Map<String, dynamic> data) async {
    _log('➕ createLocation');
    final response = await api.post(ApiConfig.ownerLocationStore, body: data);
    return _parseSingle(response['data'], LokasiModel.fromJson);
  }

  Future<LokasiModel> updateLocation(int id, Map<String, dynamic> data) async {
    _log('✏️ updateLocation($id)');
    final response = await api.put(
      ApiConfig.ownerLocationUpdate(id),
      body: data,
    );
    return _parseSingle(response['data'], LokasiModel.fromJson);
  }

  Future<bool> deleteLocation(int id) async {
    _log('🗑️ deleteLocation($id)');
    await api.delete(ApiConfig.ownerLocationDestroy(id));
    return true;
  }

  // =========================
  // ROOM
  // =========================

  Future<List<RoomModel>> getRoomsByLocation(
    int locationId, {
    int? floorId,
  }) async {
    final query = _cleanQuery({'floor_id': floorId});

    _log('🚪 getRoomsByLocation($locationId) query=$query');

    final response = await api.get(
      ApiConfig.ownerRoomsByLocation(locationId),
      query: query,
    );

    return _parseList(response['data'], RoomModel.fromJson);
  }

  Future<List<RoomModel>> getRoomsByFloor(int floorId) async {
    _log('🚪 getRoomsByFloor($floorId)');

    final response = await api.get(ApiConfig.ownerRoomsByFloor(floorId));
    return _parseList(response['data'], RoomModel.fromJson);
  }

  // =========================
  // AC UNIT
  // =========================

  Future<List<AcModel>> getAcUnits({
    int? locationId,
    int? clientId,
    int? roomId,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    final query = _cleanQuery({
      'location_id': locationId,
      'client_id': clientId,
      'room_id': roomId,
      'search': search,
      'sort_by': sortBy,
      'sort_order': sortOrder,
    });

    _log('❄️ getAcUnits query=$query');

    final response = await api.get(ApiConfig.ownerAcUnits, query: query);
    return _parseList(response['data'], AcModel.fromJson);
  }

  Future<List<AcModel>> getAcUnitsByRoom(int roomId) async {
    _log('❄️ getAcUnitsByRoom($roomId)');

    final response = await api.get(ApiConfig.ownerRoomAcUnits(roomId));
    return _parseList(response['data'], AcModel.fromJson);
  }

  Future<AcModel> getAcUnitDetail(int id) async {
    _log('🔍 getAcUnitDetail($id)');
    final response = await api.get(ApiConfig.ownerAcUnitDetail(id));
    return _parseSingle(response['data'], AcModel.fromJson);
  }

  Future<AcModel> createAcUnit(Map<String, dynamic> data) async {
    _log('➕ createAcUnit');
    final response = await api.post(ApiConfig.ownerAcUnitStore, body: data);
    return _parseSingle(response['data'], AcModel.fromJson);
  }

  Future<AcModel> updateAcUnit(int id, Map<String, dynamic> data) async {
    _log('✏️ updateAcUnit($id)');
    final response = await api.put(ApiConfig.ownerAcUnitUpdate(id), body: data);
    return _parseSingle(response['data'], AcModel.fromJson);
  }

  Future<bool> deleteAcUnit(int id) async {
    _log('🗑️ deleteAcUnit($id)');
    await api.delete(ApiConfig.ownerAcUnitDestroy(id));
    return true;
  }

  // =========================
  // SERVICE
  // =========================

  Future<List<ServisModel>> getServices({Map<String, dynamic>? query}) async {
    final q = _cleanQuery(query ?? <String, dynamic>{});

    _log('📅 getServices query=$q');

    final response = await api.get(ApiConfig.ownerServices, query: q);
    return _parseList(response['data'], ServisModel.fromMap);
  }

  Future<ServisModel> getServiceDetail(int id) async {
    _log('🔍 getServiceDetail($id)');
    final response = await api.get(ApiConfig.ownerServiceDetail(id));
    return _parseSingle(response['data'], ServisModel.fromMap);
  }

  Future<ServisModel> updateService(int id, Map<String, dynamic> data) async {
    _log('✏️ updateService($id)');
    final response = await api.put(
      ApiConfig.ownerServiceUpdate(id),
      body: data,
    );
    return _parseSingle(response['data'], ServisModel.fromMap);
  }

  Future<ServisModel> updateServiceStatus(int id, String status) async {
    _log('🔄 updateServiceStatus($id, $status)');
    final response = await api.put(
      ApiConfig.ownerServiceUpdate(id),
      body: {'status': status},
    );
    return _parseSingle(response['data'], ServisModel.fromMap);
  }

  Future<Map<String, dynamic>> confirmServiceRequest(int id) async {
    _log('✅ confirmServiceRequest($id)');
    return await api.post(ApiConfig.ownerServiceConfirmRequest(id));
  }

  Future<Map<String, dynamic>> assignTechnician(
    int serviceId,
    int technicianId,
  ) async {
    _log('👨‍🔧 assignTechnician($serviceId, $technicianId)');
    return await api.post(
      ApiConfig.ownerServiceAssignTechnician(serviceId),
      body: {
        'technician_ids': [technicianId],
      },
    );
  }

  Future<Map<String, dynamic>> assignMultipleTechnicians(
    int serviceId,
    List<int> technicianIds, {
    DateTime? tanggalDitugaskan,
  }) async {
    final body = <String, dynamic>{
      'technician_ids': technicianIds,
      if (tanggalDitugaskan != null)
        'tanggal_ditugaskan': DateFormat(
          'yyyy-MM-dd HH:mm:ss',
        ).format(tanggalDitugaskan),
    };

    _log('👨‍🔧👨‍🔧 assignMultipleTechnicians($serviceId) body=$body');

    return await api.post(
      ApiConfig.ownerServiceAssignMultipleTechnicians(serviceId),
      body: body,
    );
  }

  Future<Map<String, dynamic>> assignTechnicianPerAcGroups(
    int serviceId, {
    required List<Map<String, dynamic>> groups,
    DateTime? tanggalDitugaskan,
    bool isReassign = false,
  }) async {
    final normalizedGroups = groups
        .map((g) {
          final techId = g['technician_id'];
          final acIds = g['ac_unit_ids'];

          return <String, dynamic>{
            'technician_id': techId is int
                ? techId
                : int.tryParse(techId.toString()) ?? 0,
            'ac_unit_ids': (acIds is List)
                ? acIds
                      .map(
                        (e) => e is int ? e : int.tryParse(e.toString()) ?? 0,
                      )
                      .where((id) => id > 0)
                      .toList()
                : <int>[],
          };
        })
        .where((g) {
          final technicianId = g['technician_id'] as int? ?? 0;
          final acUnitIds = g['ac_unit_ids'] as List? ?? const [];
          return technicianId > 0 && acUnitIds.isNotEmpty;
        })
        .toList();

    final body = <String, dynamic>{
      'groups': normalizedGroups,
      'is_reassign': isReassign,
      if (tanggalDitugaskan != null)
        'tanggal_ditugaskan': DateFormat(
          'yyyy-MM-dd',
        ).format(tanggalDitugaskan),
    };

    _log('🧩 assignTechnicianPerAcGroups($serviceId) body=$body');

    return await api.post(
      ApiConfig.ownerServiceAssignTechnicianPerAc(serviceId),
      body: body,
    );
  }

  Future<Map<String, dynamic>> reassignTechnician(
    int serviceId,
    List<int> technicianIds,
  ) async {
    _log('🔁 reassignTechnician($serviceId)');
    return await api.post(
      ApiConfig.ownerServiceReassignTechnician(serviceId),
      body: {'technician_ids': technicianIds},
    );
  }

  Future<Map<String, dynamic>> confirmWork(int id) async {
    _log('✅ confirmWork($id)');
    return await api.post(ApiConfig.ownerServiceConfirmWork(id));
  }

  // =========================
  // DASHBOARD / FILTER / EXPORT
  // =========================

  Future<Map<String, dynamic>> getDashboardStats() async {
    _log('📈 getDashboardStats');
    final response = await api.get(ApiConfig.ownerDashboardStats);
    return (response['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getFilterOptions() async {
    _log('🧰 getFilterOptions');
    final response = await api.get(ApiConfig.ownerFilterOptions);
    return (response['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  Future<String> exportServices({
    String? status,
    int? clientId,
    int? locationId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = _cleanQuery({
      'status': status,
      'client_id': clientId,
      'location_id': locationId,
      'type': type,
      'start_date': startDate != null
          ? DateFormat('yyyy-MM-dd').format(startDate)
          : null,
      'end_date': endDate != null
          ? DateFormat('yyyy-MM-dd').format(endDate)
          : null,
    });

    _log('📤 exportServices query=$query');

    final response = await api.get(ApiConfig.ownerExport, query: query);
    final data = (response['data'] as Map<String, dynamic>?) ?? {};
    return (data['download_url'] ?? '').toString();
  }
}

class ClientMasterService {
  ClientMasterService({required this.api});

  final ApiClient api;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  Future<List<LokasiModel>> getLokasi() async {
    _log('📍 ClientMasterService.getLokasi()');
    final json = await api.get(ApiConfig.clientLocations);
    final data = (json['data'] as List?) ?? [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(LokasiModel.fromJson)
        .toList();
  }

  Future<List<AcModel>> getAc({int? locationId}) async {
    _log('❄️ ClientMasterService.getAc(locationId: $locationId)');
    final json = await api.get(
      ApiConfig.clientAcUnits,
      query: locationId == null ? null : {'location_id': locationId},
    );
    final data = (json['data'] as List?) ?? [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(AcModel.fromJson)
        .toList();
  }
}

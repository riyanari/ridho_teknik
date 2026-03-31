import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/ac_model.dart';
import '../models/lokasi_model.dart';
import '../models/room_model.dart';
import '../models/servis_model.dart';
import '../models/user_model.dart';
import '../services/owner_master_service.dart';

class OwnerMasterProvider with ChangeNotifier {
  final OwnerMasterService service;

  OwnerMasterProvider({required this.service});

  bool _loading = false;
  bool _submitting = false;

  String? _error;
  String? _submitError;

  List<UserModel> _clients = [];
  List<UserModel> _technicians = [];
  List<LokasiModel> _locations = [];
  List<RoomModel> _rooms = [];
  List<AcModel> _acUnits = [];
  List<ServisModel> _services = [];

  UserModel? _selectedClient;
  UserModel? _selectedTechnician;
  LokasiModel? _selectedLocation;
  RoomModel? _selectedRoom;
  AcModel? _selectedAcUnit;
  ServisModel? _selectedService;

  Map<String, dynamic>? _clientStats;
  Map<String, dynamic>? _dashboardStats;
  Map<String, dynamic>? _filterOptions;

  Map<String, dynamic> _lastServicesQuery = {};
  int _servicesFetchToken = 0;

  bool get loading => _loading;
  bool get submitting => _submitting;

  String? get error => _error;
  String? get submitError => _submitError;

  List<UserModel> get clients => _clients;
  List<UserModel> get technicians => _technicians;
  List<LokasiModel> get locations => _locations;
  List<RoomModel> get rooms => _rooms;
  List<AcModel> get acUnits => _acUnits;
  List<ServisModel> get services => _services;

  UserModel? get selectedClient => _selectedClient;
  UserModel? get selectedTechnician => _selectedTechnician;
  LokasiModel? get selectedLocation => _selectedLocation;
  RoomModel? get selectedRoom => _selectedRoom;
  AcModel? get selectedAcUnit => _selectedAcUnit;
  ServisModel? get selectedService => _selectedService;

  Map<String, dynamic>? get clientStats => _clientStats;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  Map<String, dynamic>? get filterOptions => _filterOptions;

  void _startLoading() {
    _loading = true;
    _error = null;
    notifyListeners();
  }

  void _stopLoading() {
    _loading = false;
    notifyListeners();
  }

  void _startSubmitting() {
    _submitting = true;
    _submitError = null;
    notifyListeners();
  }

  void _stopSubmitting() {
    _submitting = false;
    notifyListeners();
  }

  // =========================
  // HELPERS
  // =========================

  List<LokasiModel> getLocationsByClient(String clientId) {
    return _locations.where((loc) {
      if (loc.users.isEmpty) return false;
      return loc.users.any((user) => user.id.toString() == clientId);
    }).toList();
  }

  List<AcModel> getAcUnitsByClient(String clientId) {
    final clientLocations = getLocationsByClient(clientId);
    final locationIds = clientLocations.map((loc) => loc.id).toSet();

    return _acUnits.where((ac) => locationIds.contains(ac.locationId.toString())).toList();
  }

  List<AcModel> getAcUnitsByLocation(int locationId) {
    return _acUnits.where((ac) => ac.locationId == locationId).toList();
  }

  List<RoomModel> getRoomsByLocation(int locationId) {
    return _rooms.where((room) => room.locationId == locationId).toList();
  }

  List<ServisModel> getServicesByStatus(String status) {
    return _services
        .where((s) => s.status.name.toLowerCase() == status.toLowerCase())
        .toList();
  }

  List<ServisModel> getServicesByTechnician(int technicianId) {
    return _services.where((s) => s.technicianId == technicianId).toList();
  }

  // =========================
  // CLIENT
  // =========================

  Future<void> fetchClients({
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    _startLoading();
    try {
      _clients = await service.getClients(
        search: search,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } catch (e) {
      _error = 'Gagal mengambil data klien: $e';
    } finally {
      _stopLoading();
    }
  }

  Future<UserModel?> fetchClientDetail(int id) async {
    _startLoading();
    try {
      _selectedClient = await service.getClientDetail(id);
      return _selectedClient;
    } catch (e) {
      _error = 'Gagal mengambil detail klien: $e';
      return null;
    } finally {
      _stopLoading();
    }
  }

  Future<Map<String, dynamic>?> fetchClientStats(int id) async {
    _startLoading();
    try {
      _clientStats = await service.getClientStats(id);
      return _clientStats;
    } catch (e) {
      _error = 'Gagal mengambil statistik klien: $e';
      return null;
    } finally {
      _stopLoading();
    }
  }

  Future<UserModel?> createClient(Map<String, dynamic> data) async {
    _startSubmitting();
    try {
      final newClient = await service.createClient(data);
      _clients.insert(0, newClient);
      _selectedClient = newClient;
      return newClient;
    } catch (e) {
      _submitError = 'Gagal membuat klien: $e';
      return null;
    } finally {
      _stopSubmitting();
    }
  }

  Future<UserModel?> updateClient(int id, Map<String, dynamic> data) async {
    _startSubmitting();
    try {
      final updatedClient = await service.updateClient(id, data);

      final index = _clients.indexWhere((c) => c.id == id);
      if (index != -1) {
        _clients[index] = updatedClient;
      }

      if (_selectedClient?.id == id) {
        _selectedClient = updatedClient;
      }

      return updatedClient;
    } catch (e) {
      _submitError = 'Gagal mengupdate klien: $e';
      return null;
    } finally {
      _stopSubmitting();
    }
  }

  Future<bool> deleteClient(int id) async {
    _startSubmitting();
    try {
      final success = await service.deleteClient(id);

      if (success) {
        _clients.removeWhere((c) => c.id == id);
        if (_selectedClient?.id == id) {
          _selectedClient = null;
        }
      }

      return success;
    } catch (e) {
      _submitError = 'Gagal menghapus klien: $e';
      return false;
    } finally {
      _stopSubmitting();
    }
  }

  // =========================
  // TECHNICIAN
  // =========================

  Future<void> fetchTechnicians({
    String? search,
    String? spesialisasi,
    String? sortBy,
    String? sortOrder,
  }) async {
    _startLoading();
    try {
      _technicians = await service.getTechnicians(
        search: search,
        spesialisasi: spesialisasi,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } catch (e) {
      _error = 'Gagal mengambil data teknisi: $e';
    } finally {
      _stopLoading();
    }
  }

  Future<void> fetchAvailableTechnicians() async {
    _startLoading();
    try {
      _technicians = await service.getAvailableTechnicians();
    } catch (e) {
      _error = 'Gagal mengambil data teknisi tersedia: $e';
    } finally {
      _stopLoading();
    }
  }

  Future<UserModel?> fetchTechnicianDetail(int id) async {
    _startLoading();
    try {
      _selectedTechnician = await service.getTechnicianDetail(id);
      return _selectedTechnician;
    } catch (e) {
      _error = 'Gagal mengambil detail teknisi: $e';
      return null;
    } finally {
      _stopLoading();
    }
  }

  Future<UserModel?> createTechnician(Map<String, dynamic> data) async {
    _startSubmitting();
    try {
      final newTechnician = await service.createTechnician(data);
      _technicians.insert(0, newTechnician);
      _selectedTechnician = newTechnician;
      return newTechnician;
    } catch (e) {
      _submitError = 'Gagal membuat teknisi: $e';
      return null;
    } finally {
      _stopSubmitting();
    }
  }

  Future<UserModel?> updateTechnician(int id, Map<String, dynamic> data) async {
    _startSubmitting();
    try {
      final updatedTechnician = await service.updateTechnician(id, data);

      final index = _technicians.indexWhere((t) => t.id == id);
      if (index != -1) {
        _technicians[index] = updatedTechnician;
      }

      if (_selectedTechnician?.id == id) {
        _selectedTechnician = updatedTechnician;
      }

      return updatedTechnician;
    } catch (e) {
      _submitError = 'Gagal mengupdate teknisi: $e';
      return null;
    } finally {
      _stopSubmitting();
    }
  }

  Future<bool> deleteTechnician(int id) async {
    _startSubmitting();
    try {
      final success = await service.deleteTechnician(id);

      if (success) {
        _technicians.removeWhere((t) => t.id == id);
        if (_selectedTechnician?.id == id) {
          _selectedTechnician = null;
        }
      }

      return success;
    } catch (e) {
      _submitError = 'Gagal menghapus teknisi: $e';
      return false;
    } finally {
      _stopSubmitting();
    }
  }

  // =========================
  // LOCATION
  // =========================

  Future<void> fetchLocations({
    String? search,
    int? clientId,
    String? sortBy,
    String? sortOrder,
  }) async {
    _startLoading();
    try {
      _locations = await service.getLocations(
        search: search,
        clientId: clientId,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } catch (e) {
      _error = 'Gagal mengambil data lokasi: $e';
    } finally {
      _stopLoading();
    }
  }

  Future<LokasiModel?> createLocation(Map<String, dynamic> data) async {
    _startSubmitting();
    try {
      final newLocation = await service.createLocation(data);
      _locations.insert(0, newLocation);
      _selectedLocation = newLocation;
      return newLocation;
    } catch (e) {
      _submitError = 'Gagal membuat lokasi: $e';
      return null;
    } finally {
      _stopSubmitting();
    }
  }

  Future<LokasiModel?> updateLocation(int id, Map<String, dynamic> data) async {
    _startSubmitting();
    try {
      final updatedLocation = await service.updateLocation(id, data);

      _locations.removeWhere((l) => l.id == id);

      if (_selectedLocation?.id == id) {
        _selectedLocation = null;
      }

      return updatedLocation;
    } catch (e) {
      _submitError = 'Gagal mengupdate lokasi: $e';
      return null;
    } finally {
      _stopSubmitting();
    }
  }

  Future<bool> deleteLocation(int id) async {
    _startSubmitting();
    try {
      final success = await service.deleteLocation(id);

      if (success) {
        _locations.removeWhere((l) => l.id == id.toString());
        if (_selectedLocation?.id == id.toString()) {
          _selectedLocation = null;
        }
      }

      return success;
    } catch (e) {
      _submitError = 'Gagal menghapus lokasi: $e';
      return false;
    } finally {
      _stopSubmitting();
    }
  }

  // =========================
  // ROOM
  // =========================

  Future<void> fetchRoomsByLocation(
      int locationId, {
        int? floorId,
      }) async {
    _startLoading();
    try {
      _rooms = await service.getRoomsByLocation(locationId, floorId: floorId);
    } catch (e) {
      _error = 'Gagal mengambil data room: $e';
    } finally {
      _stopLoading();
    }
  }

  Future<RoomModel?> createRoom(
      int locationId,
      Map<String, dynamic> data,
      ) async {
    _startSubmitting();
    try {
      final newRoom = await service.createRoom(locationId, data);
      _rooms.insert(0, newRoom);
      _selectedRoom = newRoom;
      return newRoom;
    } catch (e) {
      _submitError = 'Gagal membuat room: $e';
      return null;
    } finally {
      _stopSubmitting();
    }
  }

  Future<RoomModel?> updateRoom(int roomId, Map<String, dynamic> data) async {
    _startSubmitting();
    try {
      final updatedRoom = await service.updateRoom(roomId, data);

      final index = _rooms.indexWhere((r) => r.id == roomId);
      if (index != -1) {
        _rooms[index] = updatedRoom;
      }

      if (_selectedRoom?.id == roomId) {
        _selectedRoom = updatedRoom;
      }

      return updatedRoom;
    } catch (e) {
      _submitError = 'Gagal mengupdate room: $e';
      return null;
    } finally {
      _stopSubmitting();
    }
  }

  Future<bool> deleteRoom(int roomId) async {
    _startSubmitting();
    try {
      final success = await service.deleteRoom(roomId);

      if (success) {
        _rooms.removeWhere((r) => r.id == roomId);
        if (_selectedRoom?.id == roomId) {
          _selectedRoom = null;
        }
      }

      return success;
    } catch (e) {
      _submitError = 'Gagal menghapus room: $e';
      return false;
    } finally {
      _stopSubmitting();
    }
  }

  //floor

  Future<List<Map<String, dynamic>>> fetchFloors() async {
    _startLoading();
    try {
      return await service.getFloors();
    } catch (e) {
      _error = 'Gagal mengambil data lantai: $e';
      return [];
    } finally {
      _stopLoading();
    }
  }

  // =========================
  // AC UNIT
  // =========================

  Future<void> fetchAcUnits({
    int? locationId,
    int? clientId,
    int? roomId,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    _startLoading();
    try {
      _acUnits = await service.getAcUnits(
        locationId: locationId,
        clientId: clientId,
        roomId: roomId,
        search: search,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } catch (e) {
      _error = 'Gagal mengambil data AC unit: $e';
    } finally {
      _stopLoading();
    }
  }

  Future<void> fetchAcUnitsByRoom(int roomId) async {
    _startLoading();
    try {
      _acUnits = await service.getAcUnitsByRoom(roomId);
    } catch (e) {
      _error = 'Gagal mengambil data AC per room: $e';
    } finally {
      _stopLoading();
    }
  }

  Future<AcModel?> fetchAcUnitDetail(int id) async {
    _startLoading();
    try {
      _selectedAcUnit = await service.getAcUnitDetail(id);
      return _selectedAcUnit;
    } catch (e) {
      _error = 'Gagal mengambil detail AC unit: $e';
      return null;
    } finally {
      _stopLoading();
    }
  }

  Future<AcModel?> createAcUnit(Map<String, dynamic> data) async {
    _startSubmitting();
    try {
      final newAc = await service.createAcUnit(data);
      _acUnits.insert(0, newAc);
      _selectedAcUnit = newAc;
      return newAc;
    } catch (e) {
      _submitError = 'Gagal membuat AC unit: $e';
      return null;
    } finally {
      _stopSubmitting();
    }
  }

  Future<AcModel?> updateAcUnit(int id, Map<String, dynamic> data) async {
    _startSubmitting();
    try {
      final updatedAc = await service.updateAcUnit(id, data);

      final index = _acUnits.indexWhere((a) => a.id == id);
      if (index != -1) {
        _acUnits[index] = updatedAc;
      }

      if (_selectedAcUnit?.id == id) {
        _selectedAcUnit = updatedAc;
      }

      return updatedAc;
    } catch (e) {
      _submitError = 'Gagal mengupdate AC unit: $e';
      return null;
    } finally {
      _stopSubmitting();
    }
  }

  Future<bool> deleteAcUnit(int id) async {
    _startSubmitting();
    try {
      final success = await service.deleteAcUnit(id);

      if (success) {
        _acUnits.removeWhere((a) => a.id == id);
        if (_selectedAcUnit?.id == id) {
          _selectedAcUnit = null;
        }
      }

      return success;
    } catch (e) {
      _submitError = 'Gagal menghapus AC unit: $e';
      return false;
    } finally {
      _stopSubmitting();
    }
  }

  // =========================
  // SERVICE
  // =========================

  Future<void> fetchServices({
    String? status,
    String? jenis,
    String? keyword,
    int? clientId,
    int? locationId,
    int? acUnitId,
    int? technicianId,
    int? tahun,
    int? bulan,
    String? sortBy,
    String? sortOrder,
    int? perPage,
    DateTime? startDate,
    DateTime? endDate,
    bool useLastQuery = false,
  }) async {
    _startLoading();
    final token = ++_servicesFetchToken;

    try {
      final query = useLastQuery
          ? Map<String, dynamic>.from(_lastServicesQuery)
          : <String, dynamic>{
        if (status != null) 'status': status,
        if (jenis != null) 'jenis': jenis,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (clientId != null) 'client_id': clientId,
        if (locationId != null) 'location_id': locationId,
        if (acUnitId != null) 'ac_unit_id': acUnitId,
        if (technicianId != null) 'technician_id': technicianId,
        if (tahun != null) 'tahun': tahun,
        if (bulan != null) 'bulan': bulan,
        if (sortBy != null) 'sort_by': sortBy,
        if (sortOrder != null) 'sort_order': sortOrder,
        if (perPage != null) 'per_page': perPage,
        if (startDate != null)
          'start_date': DateFormat('yyyy-MM-dd').format(startDate),
        if (endDate != null)
          'end_date': DateFormat('yyyy-MM-dd').format(endDate),
      };

      if (!useLastQuery) {
        _lastServicesQuery = Map<String, dynamic>.from(query);
      }

      final rows = await service.getServices(query: query);

      if (token != _servicesFetchToken) return;
      _services = rows;
    } catch (e) {
      if (token != _servicesFetchToken) return;
      _error = 'Gagal mengambil data servis: $e';
    } finally {
      if (token != _servicesFetchToken) return;
      _stopLoading();
    }
  }

  Future<ServisModel?> fetchServiceDetail(int id) async {
    _startLoading();
    try {
      _selectedService = await service.getServiceDetail(id);
      return _selectedService;
    } catch (e) {
      _error = 'Gagal mengambil detail servis: $e';
      return null;
    } finally {
      _stopLoading();
    }
  }

  Future<ServisModel?> updateService(int id, Map<String, dynamic> data) async {
    _startSubmitting();
    try {
      final updatedService = await service.updateService(id, data);

      final index = _services.indexWhere((s) => s.id == id);
      if (index != -1) {
        _services[index] = updatedService;
      }

      if (_selectedService?.id == id) {
        _selectedService = updatedService;
      }

      return updatedService;
    } catch (e) {
      _submitError = 'Gagal mengupdate servis: $e';
      return null;
    } finally {
      _stopSubmitting();
    }
  }

  Future<bool> confirmServiceRequest(int id) async {
    _startSubmitting();
    try {
      await service.confirmServiceRequest(id);

      final updatedService = await service.getServiceDetail(id);
      final index = _services.indexWhere((s) => s.id == id);
      if (index != -1) {
        _services[index] = updatedService;
      }
      if (_selectedService?.id == id) {
        _selectedService = updatedService;
      }

      return true;
    } catch (e) {
      _submitError = 'Gagal mengkonfirmasi service: $e';
      return false;
    } finally {
      _stopSubmitting();
    }
  }

  Future<bool> assignTechnician(int serviceId, int technicianId) async {
    _startSubmitting();
    try {
      final response = await service.assignTechnician(serviceId, technicianId);

      if (response['success'] == true) {
        await fetchServices(useLastQuery: true);
        if (_selectedService?.id == serviceId) {
          await fetchServiceDetail(serviceId);
        }
        return true;
      }

      _submitError = (response['message'] ?? 'Gagal menugaskan teknisi').toString();
      return false;
    } catch (e) {
      _submitError = 'Gagal menugaskan teknisi: $e';
      return false;
    } finally {
      _stopSubmitting();
    }
  }

  Future<bool> assignMultipleTechnicians(
      int serviceId,
      List<int> technicianIds, {
        DateTime? tanggalDitugaskan,
      }) async {
    _startSubmitting();
    try {
      final response = await service.assignMultipleTechnicians(
        serviceId,
        technicianIds,
        tanggalDitugaskan: tanggalDitugaskan,
      );

      if (response['success'] == true) {
        await fetchServices(useLastQuery: true);
        if (_selectedService?.id == serviceId) {
          await fetchServiceDetail(serviceId);
        }
        return true;
      }

      _submitError = (response['message'] ?? 'Gagal menugaskan teknisi').toString();
      return false;
    } catch (e) {
      _submitError = 'Gagal menugaskan teknisi: $e';
      return false;
    } finally {
      _stopSubmitting();
    }
  }

  Future<bool> assignTechnicianPerAcGroups(
      int serviceId, {
        required List<Map<String, dynamic>> groups,
        DateTime? tanggalDitugaskan,
        bool isReassign = false,
      }) async {
    _startSubmitting();
    try {
      final response = await service.assignTechnicianPerAcGroups(
        serviceId,
        groups: groups,
        tanggalDitugaskan: tanggalDitugaskan,
        isReassign: isReassign,
      );

      if (response['success'] == true) {
        await fetchServices(useLastQuery: true);
        if (_selectedService?.id == serviceId) {
          await fetchServiceDetail(serviceId);
        }
        return true;
      }

      _submitError = (response['message'] ?? 'Gagal assign teknisi per AC').toString();
      return false;
    } catch (e) {
      _submitError = 'Gagal assign teknisi per AC: $e';
      return false;
    } finally {
      _stopSubmitting();
    }
  }

  Future<bool> reassignTechnician(int serviceId, List<int> technicianIds) async {
    _startSubmitting();
    try {
      final response = await service.reassignTechnician(serviceId, technicianIds);

      if (response['success'] == true) {
        await fetchServices(useLastQuery: true);
        if (_selectedService?.id == serviceId) {
          await fetchServiceDetail(serviceId);
        }
        return true;
      }

      _submitError = (response['message'] ?? 'Gagal reassign teknisi').toString();
      return false;
    } catch (e) {
      _submitError = 'Gagal reassign teknisi: $e';
      return false;
    } finally {
      _stopSubmitting();
    }
  }

  Future<bool> confirmWork(int id) async {
    _startSubmitting();
    try {
      await service.confirmWork(id);

      final updatedService = await service.getServiceDetail(id);
      final index = _services.indexWhere((s) => s.id == id);
      if (index != -1) {
        _services[index] = updatedService;
      }
      if (_selectedService?.id == id) {
        _selectedService = updatedService;
      }

      return true;
    } catch (e) {
      _submitError = 'Gagal mengkonfirmasi pengerjaan: $e';
      return false;
    } finally {
      _stopSubmitting();
    }
  }

  // =========================
  // DASHBOARD
  // =========================

  Future<Map<String, dynamic>?> fetchDashboardStats() async {
    _startLoading();
    try {
      _dashboardStats = await service.getDashboardStats();
      return _dashboardStats;
    } catch (e) {
      _error = 'Gagal mengambil statistik dashboard: $e';
      return null;
    } finally {
      _stopLoading();
    }
  }

  Future<Map<String, dynamic>?> fetchFilterOptions() async {
    _startLoading();
    try {
      _filterOptions = await service.getFilterOptions();
      return _filterOptions;
    } catch (e) {
      _error = 'Gagal mengambil opsi filter: $e';
      return null;
    } finally {
      _stopLoading();
    }
  }

  Future<String?> exportServices({
    String? status,
    int? clientId,
    int? locationId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _startSubmitting();
    try {
      final url = await service.exportServices(
        status: status,
        clientId: clientId,
        locationId: locationId,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );
      return url.isEmpty ? null : url;
    } catch (e) {
      _submitError = 'Gagal export data servis: $e';
      return null;
    } finally {
      _stopSubmitting();
    }
  }

  // =========================
  // CLEAR
  // =========================

  void clearSelectedClient() {
    _selectedClient = null;
    _clientStats = null;
    notifyListeners();
  }

  void clearSelectedTechnician() {
    _selectedTechnician = null;
    notifyListeners();
  }

  void clearSelectedLocation() {
    _selectedLocation = null;
    notifyListeners();
  }

  void clearSelectedRoom() {
    _selectedRoom = null;
    notifyListeners();
  }

  void clearSelectedAcUnit() {
    _selectedAcUnit = null;
    notifyListeners();
  }

  void clearSelectedService() {
    _selectedService = null;
    notifyListeners();
  }

  void clearErrors() {
    _error = null;
    _submitError = null;
    notifyListeners();
  }

  void clearData() {
    _clients = [];
    _technicians = [];
    _locations = [];
    _rooms = [];
    _acUnits = [];
    _services = [];

    _selectedClient = null;
    _selectedTechnician = null;
    _selectedLocation = null;
    _selectedRoom = null;
    _selectedAcUnit = null;
    _selectedService = null;

    _clientStats = null;
    _dashboardStats = null;
    _filterOptions = null;

    _error = null;
    _submitError = null;
    _lastServicesQuery = {};

    notifyListeners();
  }
}
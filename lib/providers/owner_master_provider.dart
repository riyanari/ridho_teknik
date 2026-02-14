import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/ac_model.dart';
import '../models/lokasi_model.dart';
import '../models/servis_model.dart';
import '../models/user_model.dart';
import '../services/owner_master_service.dart';

class OwnerMasterProvider with ChangeNotifier {
  final OwnerMasterService service;

  OwnerMasterProvider({required this.service});

  // ===== STATE VARIABLES =====

  // Loading states
  bool _loading = false;
  bool _submitting = false;

  // Error states
  String? _error;
  String? _submitError;

  // Data lists
  List<UserModel> _clients = [];
  List<UserModel> _technicians = [];
  List<LokasiModel> _locations = [];
  List<AcModel> _acUnits = [];
  List<ServisModel> _services = [];

  // Selected items
  UserModel? _selectedClient;
  UserModel? _selectedTechnician;
  LokasiModel? _selectedLocation;
  AcModel? _selectedAcUnit;
  ServisModel? _selectedService;

  // Stats and filters
  Map<String, dynamic>? _clientStats;
  Map<String, dynamic>? _dashboardStats;
  Map<String, dynamic>? _filterOptions;
  Map<String, dynamic> _lastServicesQuery = {};
  int _servicesFetchToken = 0;

  // ===== GETTERS =====

  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;
  String? get submitError => _submitError;

  List<UserModel> get clients => _clients;
  List<UserModel> get technicians => _technicians;
  List<LokasiModel> get locations => _locations;
  List<AcModel> get acUnits => _acUnits;
  List<ServisModel> get services => _services;

  UserModel? get selectedClient => _selectedClient;
  UserModel? get selectedTechnician => _selectedTechnician;
  LokasiModel? get selectedLocation => _selectedLocation;
  AcModel? get selectedAcUnit => _selectedAcUnit;
  ServisModel? get selectedService => _selectedService;

  Map<String, dynamic>? get clientStats => _clientStats;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  Map<String, dynamic>? get filterOptions => _filterOptions;

  // ===== HELPER METHODS =====

  List<LokasiModel> getLocationsByClient(String clientId) {
    return _locations.where((loc) {
      if (loc.users != null && loc.users!.isNotEmpty) {
        return loc.users!.any((user) => user.id == clientId);
      }
      return false;
    }).toList();
  }

// Perbaiki method getAcUnitsByClient
  List<AcModel> getAcUnitsByClient(String clientId) {
    final clientLocations = getLocationsByClient(clientId);
    final locationIds = clientLocations.map((loc) => loc.id).toSet();
    return _acUnits.where((ac) => locationIds.contains(ac.lokasiId)).toList();
  }

  List<AcModel> getAcUnitsByLocation(int locationId) {
    return _acUnits.where((ac) => ac.lokasiId == locationId.toString()).toList();
  }

  // List<AcModel> getAcUnitsByClient(int clientId) {
  //   final clientLocations = getLocationsByClient(clientId);
  //   final locationIds = clientLocations.map((loc) => loc.id).toList();
  //   return _acUnits.where((ac) => locationIds.contains(ac.lokasiId)).toList();
  // }

  List<ServisModel> getServicesByStatus(String status) {
    return _services.where((s) => s.status.name.toLowerCase() == status.toLowerCase()).toList();
  }

  List<ServisModel> getServicesByTechnician(String technicianId) {
    return _services.where((s) => s.teknisiId == technicianId).toList();
  }

  // ===== CLIENT MANAGEMENT =====

  Future<void> fetchClients({
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _clients = await service.getClients(
        search: search,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } catch (e) {
      _error = 'Gagal mengambil data klien: ${e.toString()}';
      if (kDebugMode) {
        print('Error fetching clients: $e');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<UserModel?> fetchClientDetail(int id) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedClient = await service.getClientDetail(id);
      return _selectedClient;
    } catch (e) {
      _error = 'Gagal mengambil detail klien: ${e.toString()}';
      if (kDebugMode) {
        print('Error fetching client detail: $e');
      }
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchClientStats(int id) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _clientStats = await service.getClientStats(id);
      return _clientStats;
    } catch (e) {
      _error = 'Gagal mengambil statistik klien: ${e.toString()}';
      if (kDebugMode) {
        print('Error fetching client stats: $e');
      }
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<UserModel?> createClient(Map<String, dynamic> data) async {
    _submitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final newClient = await service.createClient(data);
      _clients.insert(0, newClient);
      return newClient;
    } catch (e) {
      _submitError = 'Gagal membuat klien: ${e.toString()}';
      if (kDebugMode) {
        print('Error creating client: $e');
      }
      return null;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<UserModel?> updateClient(int id, Map<String, dynamic> data) async {
    _submitting = true;
    _submitError = null;
    notifyListeners();

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
      _submitError = 'Gagal mengupdate klien: ${e.toString()}';
      if (kDebugMode) {
        print('Error updating client: $e');
      }
      return null;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteClient(int id) async {
    _submitting = true;
    _submitError = null;
    notifyListeners();

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
      _submitError = 'Gagal menghapus klien: ${e.toString()}';
      if (kDebugMode) {
        print('Error deleting client: $e');
      }
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  // ===== TECHNICIAN MANAGEMENT =====

  Future<void> fetchTechnicians({
    String? search,
    String? spesialisasi,
    String? sortBy,
    String? sortOrder,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _technicians = await service.getTechnicians(
        search: search,
        spesialisasi: spesialisasi,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } catch (e) {
      _error = 'Gagal mengambil data teknisi: ${e.toString()}';
      if (kDebugMode) {
        print('Error fetching technicians: $e');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAvailableTechnicians() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final availableTechs = await service.getAvailableTechnicians();
      _technicians = availableTechs;
    } catch (e) {
      _error = 'Gagal mengambil data teknisi tersedia: ${e.toString()}';
      if (kDebugMode) {
        print('Error fetching available technicians: $e');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<UserModel?> fetchTechnicianDetail(int id) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedTechnician = await service.getTechnicianDetail(id);
      return _selectedTechnician;
    } catch (e) {
      _error = 'Gagal mengambil detail teknisi: ${e.toString()}';
      if (kDebugMode) {
        print('Error fetching technician detail: $e');
      }
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ===== LOCATION MANAGEMENT =====

  Future<void> fetchLocations({
    String? search,
    int? clientId,
    String? sortBy,
    String? sortOrder,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _locations = await service.getLocations(
        search: search,
        clientId: clientId,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } catch (e) {
      _error = 'Gagal mengambil data lokasi: ${e.toString()}';
      if (kDebugMode) {
        print('Error fetching locations: $e');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<LokasiModel?> createLocation(Map<String, dynamic> data) async {
    _submitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final newLoc = await service.createLocation(data);

      // insert ke list (paling atas)
      _locations.insert(0, newLoc);

      // optional: set sebagai selected
      _selectedLocation = newLoc;

      return newLoc;
    } catch (e) {
      _submitError = 'Gagal membuat lokasi: ${e.toString()}';
      if (kDebugMode) {
        print('Error creating location: $e');
      }
      return null;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  // ===== AC UNIT MANAGEMENT =====

  Future<void> fetchAcUnits({
    int? locationId,
    int? clientId,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _acUnits = await service.getAcUnits(
        locationId: locationId,
        clientId: clientId,
        search: search,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } catch (e) {
      _error = 'Gagal mengambil data AC unit: ${e.toString()}';
      if (kDebugMode) {
        print('Error fetching AC units: $e');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ===== SERVICE MANAGEMENT =====

  Future<void> fetchServices({
    String? status,
    String? jenis,          // ✅ ganti dari type
    String? keyword,        // ✅ ganti dari search
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
    _loading = true;
    _error = null;
    notifyListeners();

    final int token = ++_servicesFetchToken;

    try {
      final Map<String, dynamic> query = useLastQuery ? Map.of(_lastServicesQuery) : {
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
        if (startDate != null) 'start_date': DateFormat('yyyy-MM-dd').format(startDate),
        if (endDate != null) 'end_date': DateFormat('yyyy-MM-dd').format(endDate),
      };

      if (!useLastQuery) {
        _lastServicesQuery = Map.of(query);
      }

      final rows = await service.getServices(query: query);

      // ✅ Anti race: kalau ada request lebih baru, ignore hasil lama
      if (token != _servicesFetchToken) return;

      _services = rows;
    } catch (e) {
      if (token != _servicesFetchToken) return;
      _error = 'Gagal mengambil data servis: ${e.toString()}';
      if (kDebugMode) print('Error fetching services: $e');
    } finally {
      if (token != _servicesFetchToken) return;
      _loading = false;
      notifyListeners();
    }
  }

  Future<AcModel?> createAcUnit(Map<String, dynamic> data) async {
    _submitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final newAc = await service.createAcUnit(data);

      // Insert ke list lokal (paling atas)
      _acUnits.insert(0, newAc);

      // Optional: set selected
      _selectedAcUnit = newAc;

      return newAc;
    } catch (e) {
      _submitError = 'Gagal membuat AC unit: ${e.toString()}';
      if (kDebugMode) {
        print('Error creating AC unit: $e');
      }
      return null;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<ServisModel?> fetchServiceDetail(int id) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedService = await service.getServiceDetail(id);
      return _selectedService;
    } catch (e) {
      _error = 'Gagal mengambil detail servis: ${e.toString()}';
      if (kDebugMode) {
        print('Error fetching service detail: $e');
      }
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ===== DASHBOARD =====

  Future<Map<String, dynamic>?> fetchDashboardStats() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _dashboardStats = await service.getDashboardStats();
      return _dashboardStats;
    } catch (e) {
      _error = 'Gagal mengambil statistik dashboard: ${e.toString()}';
      if (kDebugMode) {
        print('Error fetching dashboard stats: $e');
      }
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchFilterOptions() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _filterOptions = await service.getFilterOptions();
      return _filterOptions;
    } catch (e) {
      _error = 'Gagal mengambil opsi filter: ${e.toString()}';
      if (kDebugMode) {
        print('Error fetching filter options: $e');
      }
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> confirmServiceRequest(int id) async {
    _submitting = true;
    _submitError = null;
    notifyListeners();

    try {
      await service.confirmServiceRequest(id);

      // Update service status in local list
      final index = _services.indexWhere((s) => s.id == id);
      if (index != -1) {
        // Update status to 'ditugaskan'
        // You might need to fetch service detail to get updated data
        final updatedService = await service.getServiceDetail(id);
        _services[index] = updatedService;
      }

      return true;
    } catch (e) {
      _submitError = 'Gagal mengkonfirmasi service: ${e.toString()}';
      if (kDebugMode) {
        print('Error confirming service: $e');
      }
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<bool> assignTechnician(int serviceId, int technicianId) async {
    _submitting = true;
    _submitError = null;
    notifyListeners();

    try {
      print('🔄 OwnerMasterProvider.assignTechnician() dipanggil');
      print('   Service ID: $serviceId, Technician ID: $technicianId');

      final response = await service.assignTechnician(serviceId, technicianId);
      print('   API Response: $response');

      if (response['success'] == true) {
        print('   ✅ Assign technician successful');

        // Refresh services list
        await fetchServices(useLastQuery: true);
        return true;
      } else {
        print('   ❌ API returned error: ${response['message']}');
        _submitError = response['message'] ?? 'Gagal menugaskan teknisi';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Error in assignTechnician: $e');
      _submitError = 'Gagal menugaskan teknisi: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  // ===== MULTIPLE TECHNICIANS ASSIGNMENT =====

  Future<bool> assignMultipleTechnicians(
      int serviceId,
      List<int> technicianIds, {
        DateTime? tanggalDitugaskan, // ✅ optional
      }) async {
    _submitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final response = await service.assignMultipleTechnicians(
        serviceId,
        technicianIds,
        tanggalDitugaskan: tanggalDitugaskan,
      );

      if (response['success'] == true) {
        await fetchServices(useLastQuery: true);
        return true;
      }

      _submitError = response['message'] ?? 'Gagal menugaskan teknisi';
      return false;
    } catch (e) {
      _submitError = 'Gagal menugaskan teknisi: $e';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<bool> assignTechnicianPerAcGroups(
      int serviceId, {
        required List<Map<String, dynamic>> groups,
        DateTime? tanggalDitugaskan,
        bool isReassign = false, // ✅ tambah ini
      }) async {
    _submitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final response = await service.assignTechnicianPerAcGroups(
        serviceId,
        groups: groups,
        tanggalDitugaskan: tanggalDitugaskan,
        isReassign: isReassign, // ✅ teruskan
      );

      final ok = response['success'] == true;

      if (ok) {
        await fetchServices(useLastQuery: true);

        if (_selectedService?.id == serviceId.toString()) {
          await fetchServiceDetail(serviceId);
        }

        return true;
      }

      _submitError = response['message'] ?? 'Gagal assign teknisi per AC';
      return false;
    } catch (e) {
      _submitError = 'Gagal assign teknisi per AC: $e';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<bool> reassignTechnician(int serviceId, List<int> technicianIds) async {
    return await assignMultipleTechnicians(serviceId, technicianIds); // ✅
  }

  Future<bool> confirmWork(int id) async {
    _submitting = true;
    _submitError = null;
    notifyListeners();

    try {
      await service.confirmWork(id);

      // Update service status in local list
      final index = _services.indexWhere((s) => s.id == id);
      if (index != -1) {
        // Get updated service data
        final updatedService = await service.getServiceDetail(id);
        _services[index] = updatedService;
      }

      return true;
    } catch (e) {
      _submitError = 'Gagal mengkonfirmasi pengerjaan: ${e.toString()}';
      if (kDebugMode) {
        print('Error confirming work: $e');
      }
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<bool> startService(int id) async {
    _submitting = true;
    _submitError = null;
    notifyListeners();

    try {
      // You might need to create a new API endpoint for starting service
      // For now, we'll update locally
      final index = _services.indexWhere((s) => s.id == id);
      if (index != -1) {
        // Update status locally (in real app, call API)
        // This is a temporary implementation
        // _services[index].status = ... // Update status to 'dikerjakan'
      }

      return true;
    } catch (e) {
      _submitError = 'Gagal memulai service: ${e.toString()}';
      if (kDebugMode) {
        print('Error starting service: $e');
      }
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  // ===== CLEAR METHODS =====

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
    _clients.clear();
    _technicians.clear();
    _locations.clear();
    _acUnits.clear();
    _services.clear();

    _selectedClient = null;
    _selectedTechnician = null;
    _selectedLocation = null;
    _selectedAcUnit = null;
    _selectedService = null;

    _clientStats = null;
    _dashboardStats = null;
    _filterOptions = null;

    _error = null;
    _submitError = null;

    notifyListeners();
  }
}
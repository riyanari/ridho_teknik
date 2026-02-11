class ApiConfig {
  static const String baseUrl = "https://cvrt.thepride.id/api"; // android emulator
  // static const String baseUrl = "http://10.0.2.2:8000/api"; // android emulator
  // static const String baseUrl = "http://192.168.1.4:8000/api"; // ios simulator
  // static const String baseUrl = "http://localhost:8000/api"; // web/flutter web

  // ===== AUTH =====
  static String get login => "$baseUrl/login";
  static String get logout => "$baseUrl/logout";
  static String get me => "$baseUrl/me";

  // ===== OWNER =====

  // Client CRUD
  static String get ownerClients => "$baseUrl/owner/clients";
  static String ownerClientDetail(int id) => "$baseUrl/owner/clients/$id";
  static String ownerClientStats(int id) => "$baseUrl/owner/clients/$id/stats";
  static String get ownerClientStore => "$baseUrl/owner/clients";
  static String ownerClientUpdate(int id) => "$baseUrl/owner/clients/$id";
  static String ownerClientDestroy(int id) => "$baseUrl/owner/clients/$id";

  // Technician CRUD
  static String get ownerTechnicians => "$baseUrl/owner/technicians";
  static String get ownerAvailableTechnicians => "$baseUrl/owner/technicians/available";
  static String ownerTechnicianDetail(int id) => "$baseUrl/owner/technicians/$id";
  static String get ownerTechnicianStore => "$baseUrl/owner/technicians";
  static String ownerTechnicianUpdate(int id) => "$baseUrl/owner/technicians/$id";
  static String ownerTechnicianDestroy(int id) => "$baseUrl/owner/technicians/$id";

  // Location CRUD
  static String get ownerLocations => "$baseUrl/owner/locations";
  static String get ownerLocationStore => "$baseUrl/owner/locations";
  static String ownerLocationUpdate(int id) => "$baseUrl/owner/locations/$id";
  static String ownerLocationDestroy(int id) => "$baseUrl/owner/locations/$id";

  // AC Unit CRUD
  static String get ownerAcUnits => "$baseUrl/owner/ac-units";
  static String ownerAcUnitDetail(int id) => "$baseUrl/owner/ac-units/$id";
  static String get ownerAcUnitStore => "$baseUrl/owner/ac-units";
  static String ownerAcUnitUpdate(int id) => "$baseUrl/owner/ac-units/$id";
  static String ownerAcUnitDestroy(int id) => "$baseUrl/owner/ac-units/$id";

  // Service Management
  static String get ownerServices => "$baseUrl/owner/servis";
  static String ownerServiceDetail(int id) => "$baseUrl/owner/servis/$id";
  static String ownerServiceUpdate(int id) => "$baseUrl/owner/servis/$id";
  static String ownerServiceByStatus(String status) => "$baseUrl/owner/servis/status/$status";
  static String ownerServiceConfirmRequest(int id) => "$baseUrl/owner/servis/$id/konfirmasi-request";
  static String ownerServiceAssignTechnician(int id) => "$baseUrl/owner/servis/$id/assign-teknisi";
  static String ownerServiceConfirmWork(int id) => "$baseUrl/owner/servis/$id/konfirmasi-pengerjaan";

  // Di class ApiConfig, tambahkan:
// Service Management - Multiple Technicians
  static String ownerServiceAssignMultipleTechnicians(int id) => "$baseUrl/owner/servis/$id/assign-multiple-teknisi";
  static String ownerServiceReassignTechnician(int id) => "$baseUrl/owner/servis/$id/reassign-teknisi";

  static String ownerServiceAssignTechnicianPerAc(int id) => "$baseUrl/owner/servis/$id/assign-teknisi-per-ac";

  // Dashboard & Reports
  static String get ownerDashboardStats => "$baseUrl/owner/servis/dashboard";
  static String get ownerFilterOptions => "$baseUrl/owner/servis/filter-options";
  static String get ownerExport => "$baseUrl/owner/servis/export";

  // ===== CLIENT =====

  // Locations
  static String get clientLocations => "$baseUrl/client/lokasi";
  static String get clientAcUnits => "$baseUrl/client/ac";

  // Service Requests
  static String get clientServiceCuci => "$baseUrl/client/servis/cuci";
  static String get clientServicePerbaikan => "$baseUrl/client/servis/perbaikan";
  static String get clientServiceInstalasi => "$baseUrl/client/servis/instalasi";
  static String get clientServices => "$baseUrl/client/servis";

  // ===== TEKNISI =====

  // Service Management
  static String get technicianTasks => "$baseUrl/teknisi/servis/tugas";
  static String technicianStartService(int serviceId) => "$baseUrl/teknisi/servis/$serviceId/mulai";
  static String technicianStartItem(int itemId) => "$baseUrl/teknisi/servis-items/$itemId/mulai";
  static String technicianUpdateItemProgress(int itemId) => "$baseUrl/teknisi/servis-items/$itemId/upload-foto";
  static String technicianFinishItem(int itemId) => "$baseUrl/teknisi/servis-items/$itemId/selesaikan";
  static String technicianFinishService(int serviceId) => "$baseUrl/teknisi/servis/$serviceId/selesaikan";

  // Helper methods for query parameters
  static String buildUrlWithParams(String baseUrl, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) {
      return baseUrl;
    }

    final uri = Uri.parse(baseUrl);
    final queryParams = Map<String, String>.from(params.map((key, value) {
      return MapEntry(key, value.toString());
    }));

    return uri.replace(queryParameters: queryParams).toString();
  }
}
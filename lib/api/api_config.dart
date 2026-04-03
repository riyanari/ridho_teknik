class ApiConfig {
  static const String baseUrl = "https://cvrt.thepride.id/api";
  // static const String baseUrl = "http://10.0.2.2:8000/api";
  // static const String baseUrl = "http://192.168.1.4:8000/api";
  // static const String baseUrl = "http://localhost:8000/api";

  // AUTH
  static String get login => "$baseUrl/login";
  static String get logout => "$baseUrl/logout";
  static String get me => "$baseUrl/me";

  // MEDIA
  static String serviceItemPhoto(int itemId) =>
      "$baseUrl/media/service-item/$itemId/photo";

  // OWNER - CLIENTS
  static String get ownerClients => "$baseUrl/owner/clients";
  static String get ownerClientStore => "$baseUrl/owner/clients";
  static String ownerClientDetail(int id) => "$baseUrl/owner/clients/$id";
  static String ownerClientStats(int id) => "$baseUrl/owner/clients/$id/stats";
  static String ownerClientUpdate(int id) => "$baseUrl/owner/clients/$id";
  static String ownerClientDestroy(int id) => "$baseUrl/owner/clients/$id";

  // OWNER - TECHNICIANS
  static String get ownerTechnicians => "$baseUrl/owner/technicians";
  static String get ownerTechnicianStore => "$baseUrl/owner/technicians";
  static String get ownerAvailableTechnicians =>
      "$baseUrl/owner/technicians/available";
  static String ownerTechnicianDetail(int id) =>
      "$baseUrl/owner/technicians/$id";
  static String ownerTechnicianUpdate(int id) =>
      "$baseUrl/owner/technicians/$id";
  static String ownerTechnicianDestroy(int id) =>
      "$baseUrl/owner/technicians/$id";

  // OWNER - LOCATIONS
  static String get ownerLocations => "$baseUrl/owner/locations";
  static String get ownerLocationStore => "$baseUrl/owner/locations";
  static String ownerLocationUpdate(int id) => "$baseUrl/owner/locations/$id";
  static String ownerLocationDestroy(int id) => "$baseUrl/owner/locations/$id";

  // OWNER - FLOORS (MASTER UMUM)
  static String get ownerFloors => "$baseUrl/owner/floors";
  static String get ownerFloorStore => "$baseUrl/owner/floors";
  static String ownerFloorDetail(int floorId) =>
      "$baseUrl/owner/floors/$floorId";
  static String ownerFloorUpdate(int floorId) =>
      "$baseUrl/owner/floors/$floorId";
  static String ownerFloorDestroy(int floorId) =>
      "$baseUrl/owner/floors/$floorId";

  // OWNER - ROOMS
  static String ownerRoomsByLocation(int locationId) =>
      "$baseUrl/owner/locations/$locationId/rooms";
  static String ownerRoomStore(int locationId) =>
      "$baseUrl/owner/locations/$locationId/rooms";
  static String ownerRoomDetail(int roomId) => "$baseUrl/owner/rooms/$roomId";
  static String ownerRoomUpdate(int roomId) => "$baseUrl/owner/rooms/$roomId";
  static String ownerRoomDestroy(int roomId) => "$baseUrl/owner/rooms/$roomId";
  static String ownerRoomAcUnits(int roomId) =>
      "$baseUrl/owner/rooms/$roomId/ac-units";

  // OWNER - AC UNITS
  static String get ownerAcUnits => "$baseUrl/owner/ac-units";
  static String get ownerAcUnitStore => "$baseUrl/owner/ac-units";
  static String ownerAcUnitDetail(int id) => "$baseUrl/owner/ac-units/$id";
  static String ownerAcUnitUpdate(int id) => "$baseUrl/owner/ac-units/$id";
  static String ownerAcUnitDestroy(int id) => "$baseUrl/owner/ac-units/$id";

  // OWNER - AC MASTER
  static String get ownerAcMasterBrands => "$baseUrl/owner/ac-master/brands";
  static String get ownerAcMasterTypes => "$baseUrl/owner/ac-master/types";
  static String get ownerAcMasterSeries => "$baseUrl/owner/ac-master/series";
  static String get ownerAcMasterCapacities => "$baseUrl/owner/ac-master/capacities";
  static String get ownerAcMasterFormOptions => "$baseUrl/owner/ac-master/form-options";

  // OWNER - SERVICES
  static String get ownerServices => "$baseUrl/owner/servis";
  static String ownerServiceDetail(int id) => "$baseUrl/owner/servis/$id";
  static String ownerServiceUpdate(int id) => "$baseUrl/owner/servis/$id";
  static String get upcomingVisits => "$baseUrl/owner/servis/upcoming-visits";
  static String get reminderAc3Bulan => "$baseUrl/owner/servis/reminder-ac-3-bulan";
  static String get reminderAc6Bulan => "$baseUrl/owner/servis/reminder-ac-6-bulan";
  static String ownerServiceByStatus(String status) =>
      "$baseUrl/owner/servis/status/$status";
  static String ownerServiceConfirmRequest(int id) =>
      "$baseUrl/owner/servis/$id/konfirmasi-request";
  static String ownerServiceAssignTechnician(int id) =>
      "$baseUrl/owner/servis/$id/assign-teknisi";
  static String ownerServiceConfirmWork(int id) =>
      "$baseUrl/owner/servis/$id/konfirmasi-pengerjaan";
  static String ownerServiceAssignMultipleTechnicians(int id) =>
      "$baseUrl/owner/servis/$id/assign-multiple-teknisi";
  static String ownerServiceAssignTechnicianPerAc(int id) =>
      "$baseUrl/owner/servis/$id/assign-teknisi-per-ac";
  static String ownerServiceReassignTechnician(int id) =>
      "$baseUrl/owner/servis/$id/reassign-teknisi";

  // OWNER - DASHBOARD
  static String get ownerDashboardStats => "$baseUrl/owner/servis/dashboard";
  static String get ownerFilterOptions =>
      "$baseUrl/owner/servis/filter-options";
  static String get ownerExport => "$baseUrl/owner/servis/export";

  // CLIENT
  static String get clientLocations => "$baseUrl/client/lokasi";
  static String get clientAcUnits => "$baseUrl/client/ac";
  static String get clientServices => "$baseUrl/client/servis";
  static String clientServiceDetail(int id) => "$baseUrl/client/servis/$id";
  static String get clientServiceCuci => "$baseUrl/client/servis/cuci";
  static String get clientServicePerbaikan => "$baseUrl/client/servis/perbaikan";
  static String get clientServiceInstalasi => "$baseUrl/client/servis/instalasi";

  // TEKNISI
  static String get technicianTasks => "$baseUrl/teknisi/servis/tugas";
  static String technicianStartService(int serviceId) =>
      "$baseUrl/teknisi/servis/$serviceId/mulai";
  static String technicianFinishService(int serviceId) =>
      "$baseUrl/teknisi/servis/$serviceId/selesaikan";
  static String technicianStartItem(int itemId) =>
      "$baseUrl/teknisi/servis-items/$itemId/mulai";
  static String technicianUpdateItemProgress(int itemId) =>
      "$baseUrl/teknisi/servis-items/$itemId/upload-foto";
  static String technicianFinishItem(int itemId) =>
      "$baseUrl/teknisi/servis-items/$itemId/selesaikan";

  static String buildUrlWithParams(
      String url,
      Map<String, dynamic>? params,
      ) {
    if (params == null || params.isEmpty) return url;

    final uri = Uri.parse(url);
    final queryParams = params.map(
          (key, value) => MapEntry(key, value.toString()),
    );

    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        ...queryParams,
      },
    ).toString();
  }
}
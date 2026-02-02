class ApiConfig {
  static const String baseUrl = "http://10.0.2.2:8000/api"; // android emulator
  // static const String baseUrl = "http://127.0.0.1:8000/api"; // ios simulator

  // AUTH
  static String login = "$baseUrl/login";
  static String logout = "$baseUrl/logout";
  static String me = "$baseUrl/me";

  // ===== OWNER =====
  static String ownerClients = "$baseUrl/owner/clients";
  static String ownerTeknisi = "$baseUrl/owner/teknisi";

  static String ownerLokasiIndex = "$baseUrl/owner/lokasi";
  static String ownerLokasiStore = "$baseUrl/owner/lokasi";
  static String ownerLokasiUpdate(int id) => "$baseUrl/owner/lokasi/$id";
  static String ownerLokasiDestroy(int id) => "$baseUrl/owner/lokasi/$id";

  static String ownerAcIndex = "$baseUrl/owner/ac";
  static String ownerAcStore = "$baseUrl/owner/ac";
  static String ownerAcUpdate(int id) => "$baseUrl/owner/ac/$id";
  static String ownerAcDestroy(int id) => "$baseUrl/owner/ac/$id";

  static String ownerKeluhan = "$baseUrl/owner/keluhan";
  static String ownerServis = "$baseUrl/owner/servis";
  static String ownerServisAssign(int id) => "$baseUrl/owner/servis/$id/assign";
  static String ownerServisConfirm(int id) => "$baseUrl/owner/servis/$id/confirm";

  // ===== CLIENT =====
  static String clientLokasi = "$baseUrl/client/lokasi";
  static String clientAc = "$baseUrl/client/ac";

  static String clientKeluhanIndex = "$baseUrl/client/keluhan";
  static String clientKeluhanStore = "$baseUrl/client/keluhan";

  static String clientServisIndex = "$baseUrl/client/servis";
  static String clientServisStore = "$baseUrl/client/servis";
  static String clientServisShow(int id) => "$baseUrl/client/servis/$id";

  // ===== TEKNISI =====
  static String teknisiDashboard = "$baseUrl/teknisi/dashboard";
  static String teknisiServisIndex = "$baseUrl/teknisi/servis";
  static String teknisiServisShow(int id) => "$baseUrl/teknisi/servis/$id";
  static String teknisiServisUpdateStatus(int id) => "$baseUrl/teknisi/servis/$id/status";
  static String teknisiServisReport(int id) => "$baseUrl/teknisi/servis/$id/report";
  static String teknisiServisUpload(int id) => "$baseUrl/teknisi/servis/$id/upload";
}

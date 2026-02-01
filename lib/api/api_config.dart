class ApiConfig {
  static const String baseUrl = "http://10.0.2.2:8000/api"; // android emulator
  // static const String baseUrl = "http://127.0.0.1:8000/api"; // ios simulator

  static String login = "$baseUrl/login";
  static String logout = "$baseUrl/logout";
  static String me = "$baseUrl/me";
}

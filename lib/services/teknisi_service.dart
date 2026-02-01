import 'dart:convert';
import 'package:http/http.dart' as http;

import '../api/api_config.dart';
import 'token_store.dart';

class TeknisiService {
  final TokenStore tokenStore;
  TeknisiService({required this.tokenStore});

  Future<Map<String, dynamic>> fetchDashboard() async {
    final token = await tokenStore.getToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/teknisi/dashboard');

    final res = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': token,
      },
    );

    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Response bukan JSON: ${res.body}');
    }

    if (res.statusCode == 200) return body;

    throw Exception(body['message']?.toString() ?? 'Gagal load dashboard (${res.statusCode})');
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/token_store.dart';

class ApiClient {
  ApiClient({required this.store});
  final TokenStore store;

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (auth) {
      final token = await store.getToken();
      if (token != null && token.isNotEmpty) {
        h['Authorization'] = token; // "Bearer xxx"
      }
    }
    return h;
  }

  Uri _uri(String url, [Map<String, dynamic>? query]) {
    final u = Uri.parse(url);
    if (query == null || query.isEmpty) return u;

    final qp = <String, String>{};
    query.forEach((k, v) {
      if (v == null) return;
      qp[k] = v.toString();
    });

    return u.replace(queryParameters: {
      ...u.queryParameters,
      ...qp,
    });
  }

  Map<String, dynamic> _safeJson(String s) {
    try {
      final j = jsonDecode(s);
      if (j is Map<String, dynamic>) return j;
      return {'data': j};
    } catch (_) {
      return {'message': s};
    }
  }

  Map<String, dynamic> _handle(http.Response res) {
    final json = _safeJson(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return json;

    final msg = (json['message'] ?? json['error'] ?? 'Request gagal').toString();
    throw Exception('$msg (${res.statusCode})');
  }

  Future<Map<String, dynamic>> get(
      String url, {
        Map<String, dynamic>? query,
      }) async {
    final res = await http.get(_uri(url, query), headers: await _headers());
    return _handle(res);
  }

  Future<Map<String, dynamic>> post(
      String url, {
        Map<String, dynamic>? query,
        Map<String, dynamic>? body,
      }) async {
    final res = await http.post(
      _uri(url, query),
      headers: await _headers(),
      body: jsonEncode(body ?? {}),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> put(
      String url, {
        Map<String, dynamic>? query,
        Map<String, dynamic>? body,
      }) async {
    final res = await http.put(
      _uri(url, query),
      headers: await _headers(),
      body: jsonEncode(body ?? {}),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> delete(
      String url, {
        Map<String, dynamic>? query,
      }) async {
    final res = await http.delete(_uri(url, query), headers: await _headers());
    return _handle(res);
  }
}

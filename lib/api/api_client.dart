import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/token_store.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({required this.store});

  final TokenStore store;

  Future<Map<String, String>> _headers({
    bool auth = true,
    bool json = true,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (json) {
      headers['Content-Type'] = 'application/json';
    }

    if (auth) {
      final token = await store.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] =
        token.startsWith('Bearer ') ? token : 'Bearer $token';
      }
    }

    return headers;
  }

  Uri _uri(String url, [Map<String, dynamic>? query]) {
    final uri = Uri.parse(url);

    if (query == null || query.isEmpty) {
      return uri;
    }

    final queryParams = <String, String>{};
    query.forEach((key, value) {
      if (value == null) return;
      queryParams[key] = value.toString();
    });

    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        ...queryParams,
      },
    );
  }

  Map<String, dynamic> _safeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    } catch (_) {
      return {'message': body};
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  Never _throwApiError(Map<String, dynamic> json, int statusCode) {
    final message =
    (json['message'] ?? json['error'] ?? 'Request gagal').toString();

    final rawErrors = json['errors'];
    Map<String, dynamic>? parsedErrors;

    if (rawErrors is Map<String, dynamic>) {
      parsedErrors = rawErrors;
    }

    if (parsedErrors != null && parsedErrors.isNotEmpty) {
      final details = parsedErrors.entries.map((entry) {
        final value = entry.value;
        if (value is List) {
          return '${entry.key}: ${value.join(", ")}';
        }
        return '${entry.key}: $value';
      }).join(' | ');

      throw ApiException(
        '$message - $details',
        statusCode: statusCode,
        errors: parsedErrors,
      );
    }

    throw ApiException(
      message,
      statusCode: statusCode,
    );
  }

  Map<String, dynamic> _handle(http.Response response) {
    final json = _safeJson(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    _throwApiError(json, response.statusCode);
  }

  Future<Map<String, dynamic>> get(
      String url, {
        Map<String, dynamic>? query,
        bool auth = true,
      }) async {
    final uri = _uri(url, query);
    _log('📤 [GET] $uri');

    final response = await http.get(
      uri,
      headers: await _headers(auth: auth),
    );

    _log('📥 [GET] status=${response.statusCode}');
    _log('📥 [GET] body=${response.body}');
    return _handle(response);
  }

  Future<Map<String, dynamic>> post(
      String url, {
        Map<String, dynamic>? query,
        Map<String, dynamic>? body,
        bool auth = true,
      }) async {
    final uri = _uri(url, query);
    final requestBody = jsonEncode(body ?? {});

    _log('📤 [POST] $uri');
    _log('📤 [POST] body=$requestBody');

    final response = await http.post(
      uri,
      headers: await _headers(auth: auth),
      body: requestBody,
    );

    _log('📥 [POST] status=${response.statusCode}');
    _log('📥 [POST] body=${response.body}');
    return _handle(response);
  }

  Future<Map<String, dynamic>> put(
      String url, {
        Map<String, dynamic>? query,
        Map<String, dynamic>? body,
        bool auth = true,
      }) async {
    final uri = _uri(url, query);
    final requestBody = jsonEncode(body ?? {});

    _log('📤 [PUT] $uri');
    _log('📤 [PUT] body=$requestBody');

    final response = await http.put(
      uri,
      headers: await _headers(auth: auth),
      body: requestBody,
    );

    _log('📥 [PUT] status=${response.statusCode}');
    _log('📥 [PUT] body=${response.body}');
    return _handle(response);
  }

  Future<Map<String, dynamic>> patch(
      String url, {
        Map<String, dynamic>? query,
        Map<String, dynamic>? body,
        bool auth = true,
      }) async {
    final uri = _uri(url, query);
    final requestBody = jsonEncode(body ?? {});

    _log('📤 [PATCH] $uri');
    _log('📤 [PATCH] body=$requestBody');

    final response = await http.patch(
      uri,
      headers: await _headers(auth: auth),
      body: requestBody,
    );

    _log('📥 [PATCH] status=${response.statusCode}');
    _log('📥 [PATCH] body=${response.body}');
    return _handle(response);
  }

  Future<Map<String, dynamic>> delete(
      String url, {
        Map<String, dynamic>? query,
        Map<String, dynamic>? body,
        bool auth = true,
      }) async {
    final uri = _uri(url, query);
    _log('📤 [DELETE] $uri');

    if (body == null) {
      final response = await http.delete(
        uri,
        headers: await _headers(auth: auth),
      );

      _log('📥 [DELETE] status=${response.statusCode}');
      _log('📥 [DELETE] body=${response.body}');
      return _handle(response);
    }

    final request = http.Request('DELETE', uri);
    request.headers.addAll(await _headers(auth: auth));
    request.body = jsonEncode(body);

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    _log('📥 [DELETE] status=${response.statusCode}');
    _log('📥 [DELETE] body=${response.body}');
    return _handle(response);
  }

  Future<Map<String, dynamic>> postMultipart(
      String url, {
        Map<String, String>? fields,
        required List<http.MultipartFile> files,
        bool auth = true,
      }) async {
    final uri = Uri.parse(url);
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll(await _headers(auth: auth, json: false));

    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }

    request.files.addAll(files);

    _log('📤 [MULTIPART POST] $url');
    _log('   fields: $fields');
    _log('   files count: ${files.length}');

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    _log('📥 [MULTIPART POST] status=${response.statusCode}');
    _log('📥 [MULTIPART POST] body=${response.body}');
    return _handle(response);
  }

  Future<Map<String, dynamic>> putMultipart(
      String url, {
        Map<String, String>? fields,
        required List<http.MultipartFile> files,
        bool auth = true,
      }) async {
    final uri = Uri.parse(url);
    final request = http.MultipartRequest('PUT', uri);

    request.headers.addAll(await _headers(auth: auth, json: false));

    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }

    request.files.addAll(files);

    _log('📤 [MULTIPART PUT] $url');
    _log('   fields: $fields');
    _log('   files count: ${files.length}');

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    _log('📥 [MULTIPART PUT] status=${response.statusCode}');
    _log('📥 [MULTIPART PUT] body=${response.body}');
    return _handle(response);
  }
}

class ApiResponse<T> {
  final String message;
  final List<T> data;
  final int? total;
  final int? currentPage;
  final int? lastPage;

  ApiResponse({
    required this.message,
    required this.data,
    this.total,
    this.currentPage,
    this.lastPage,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJson,
      ) {
    final rawData = json['data'];

    if (rawData is List) {
      return ApiResponse<T>(
        message: (json['message'] ?? 'OK').toString(),
        data: rawData
            .whereType<Map<String, dynamic>>()
            .map(fromJson)
            .toList(),
        total: json['total'] as int?,
        currentPage: json['current_page'] as int?,
        lastPage: json['last_page'] as int?,
      );
    }

    if (rawData is Map<String, dynamic>) {
      final nestedList = rawData['data'];

      return ApiResponse<T>(
        message: (json['message'] ?? 'OK').toString(),
        data: (nestedList is List)
            ? nestedList
            .whereType<Map<String, dynamic>>()
            .map(fromJson)
            .toList()
            : <T>[],
        total: rawData['total'] as int?,
        currentPage: rawData['current_page'] as int?,
        lastPage: rawData['last_page'] as int?,
      );
    }

    return ApiResponse<T>(
      message: (json['message'] ?? 'OK').toString(),
      data: <T>[],
    );
  }
}
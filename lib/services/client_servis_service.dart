import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/servis_model.dart';
import '../services/token_store.dart';

class ClientServisService {
  final ApiClient api;
  final TokenStore store;

  ClientServisService({
    required this.api,
    required this.store,
  });

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  List<ServisModel> _extractServisList(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(ServisModel.fromMap)
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is List) {
        return nested
            .whereType<Map<String, dynamic>>()
            .map(ServisModel.fromMap)
            .toList();
      }

      if (data['id'] != null) {
        return [ServisModel.fromMap(data)];
      }
    }

    return <ServisModel>[];
  }

  Map<String, dynamic> _extractObject(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    return response;
  }

  Future<List<ServisModel>> getServis({
    int? acId,
    int? lokasiId,
  }) async {
    try {
      final params = <String, dynamic>{
        if (acId != null) 'ac_id': acId,
        if (lokasiId != null) 'lokasi_id': lokasiId,
      };

      _log('📋 getServis params=$params');

      final json = await api.get(
        ApiConfig.clientServices,
        query: params.isEmpty ? null : params,
      );

      return _extractServisList(json);
    } catch (e) {
      throw Exception('Gagal mengambil data servis client: $e');
    }
  }

  Future<ServisModel?> getServisDetail(int id) async {
    try {
      final json = await api.get(ApiConfig.clientServiceDetail(id));
      final data = _extractObject(json);

      if (data['id'] != null) {
        return ServisModel.fromMap(data);
      }

      return null;
    } catch (e) {
      throw Exception('Gagal mengambil detail servis client: $e');
    }
  }

  Future<ServisModel?> requestCuci({
    required int locationId,
    required bool semuaAc,
    List<int>? acUnits,
    String? catatan,
    String? tanggalBerkunjung,
  }) async {
    try {
      final body = <String, dynamic>{
        'location_id': locationId,
        'semua_ac': semuaAc,
        if (!semuaAc && acUnits != null && acUnits.isNotEmpty)
          'ac_units': acUnits,
        if (catatan != null && catatan.trim().isNotEmpty)
          'catatan': catatan.trim(),
        if (tanggalBerkunjung != null && tanggalBerkunjung.trim().isNotEmpty)
          'tanggal_berkunjung': tanggalBerkunjung.trim(),
      };

      _log('🧼 requestCuci body=$body');

      final json = await api.post(
        ApiConfig.clientServiceCuci,
        body: body,
      );

      final data = _extractObject(json);
      if (data['id'] != null) {
        return ServisModel.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengirim request cuci: $e');
    }
  }

  Future<ServisModel?> requestPerbaikan({
    required int locationId,
    required int acUnitId,
    required String keluhan,
    required String priority,
    List<File>? fotoKeluhan,
    String? tanggalBerkunjung,
  }) async {
    try {
      if (fotoKeluhan != null && fotoKeluhan.isNotEmpty) {
        final data = await _requestPerbaikanWithFiles(
          locationId: locationId,
          acUnitId: acUnitId,
          keluhan: keluhan,
          priority: priority,
          fotoKeluhan: fotoKeluhan,
          tanggalBerkunjung: tanggalBerkunjung,
        );

        return data['id'] != null ? ServisModel.fromMap(data) : null;
      }

      final body = <String, dynamic>{
        'location_id': locationId,
        'ac_unit_id': acUnitId,
        'keluhan': keluhan,
        'priority': priority,
        if (tanggalBerkunjung != null && tanggalBerkunjung.trim().isNotEmpty)
          'tanggal_berkunjung': tanggalBerkunjung.trim(),
      };

      _log('🛠️ requestPerbaikan body=$body');

      final json = await api.post(
        ApiConfig.clientServicePerbaikan,
        body: body,
      );

      final data = _extractObject(json);
      return data['id'] != null ? ServisModel.fromMap(data) : null;
    } catch (e) {
      throw Exception('Gagal mengirim request perbaikan: $e');
    }
  }

  Future<Map<String, dynamic>> _requestPerbaikanWithFiles({
    required int locationId,
    required int acUnitId,
    required String keluhan,
    required String priority,
    required List<File> fotoKeluhan,
    String? tanggalBerkunjung,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.clientServicePerbaikan),
    );

    final token = await store.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan. Silakan login kembali.');
    }

    request.headers['Authorization'] =
    token.startsWith('Bearer ') ? token : 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['location_id'] = locationId.toString();
    request.fields['ac_unit_id'] = acUnitId.toString();
    request.fields['keluhan'] = keluhan;
    request.fields['priority'] = priority;

    if (tanggalBerkunjung != null && tanggalBerkunjung.trim().isNotEmpty) {
      request.fields['tanggal_berkunjung'] = tanggalBerkunjung.trim();
    }

    for (int i = 0; i < fotoKeluhan.length; i++) {
      final file = fotoKeluhan[i];
      request.files.add(
        await http.MultipartFile.fromPath(
          'foto_keluhan[$i]',
          file.path,
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _extractObject(json);
    }

    final errorJson = jsonDecode(response.body);
    throw Exception(
      'Failed to upload: ${response.statusCode} ${errorJson['message'] ?? response.body}',
    );
  }
}
import 'package:http/http.dart' as http;

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/servis_model.dart';

class TechnicianTaskService {
  final ApiClient api;

  TechnicianTaskService({required this.api});

  // ================= PARSER =================

  ServisModel _parseSingle(dynamic data) {
    if (data is Map<String, dynamic>) {
      return ServisModel.fromMap(data); // ✅ FIX
    }
    throw Exception('Format data tidak valid');
  }

  List<ServisModel> _parseList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => ServisModel.fromMap(e)) // ✅ FIX
          .toList();
    }
    return [];
  }

  // ================= API =================

  Future<List<ServisModel>> getTasks() async {
    final res = await api.get(ApiConfig.technicianTasks);
    return _parseList(res['data']);
  }

  Future<ServisModel> startService(int serviceId) async {
    final res = await api.post(
      ApiConfig.technicianStartService(serviceId),
      body: {},
    );
    return _parseSingle(res['data']);
  }

  Future<ServisModel> startItem(int itemId) async {
    final res = await api.post(
      ApiConfig.technicianStartItem(itemId),
      body: {},
    );
    return _parseSingle(res['data']);
  }

  Future<List<http.MultipartFile>> _files(
      String field,
      List<String> paths,
      ) async {
    return Future.wait(
      paths.map((p) => http.MultipartFile.fromPath(field, p)),
    );
  }

  Future<ServisModel> updateItemProgress(
      int itemId, {
        String? diagnosa,
        String? tindakan,
        List<String> fotoSebelum = const [],
        List<String> fotoPengerjaan = const [],
        List<String> fotoSesudah = const [],
      }) async {
    final fields = <String, String>{};

    if (diagnosa?.trim().isNotEmpty == true) {
      fields['diagnosa'] = diagnosa!.trim();
    }
    if (tindakan?.trim().isNotEmpty == true) {
      fields['tindakan'] = tindakan!.trim();
    }

    final files = <http.MultipartFile>[
      ...await _files('foto_sebelum[]', fotoSebelum),
      ...await _files('foto_pengerjaan[]', fotoPengerjaan),
      ...await _files('foto_sesudah[]', fotoSesudah),
    ];

    final res = await api.postMultipart(
      ApiConfig.technicianUpdateItemProgress(itemId),
      fields: fields,
      files: files,
    );

    return _parseSingle(res['data']);
  }

  Future<ServisModel> finishItem(
      int itemId, {
        String? diagnosa,
        String? tindakan,
        List<String> fotoSesudah = const [],
      }) async {
    final fields = <String, String>{};

    if (diagnosa?.trim().isNotEmpty == true) {
      fields['diagnosa'] = diagnosa!.trim();
    }
    if (tindakan?.trim().isNotEmpty == true) {
      fields['tindakan'] = tindakan!.trim();
    }

    final files = await _files('foto_sesudah[]', fotoSesudah);

    final res = await api.postMultipart(
      ApiConfig.technicianFinishItem(itemId),
      fields: fields,
      files: files,
    );

    return _parseSingle(res['data']);
  }

  Future<ServisModel> finishService(int serviceId) async {
    final res = await api.post(
      ApiConfig.technicianFinishService(serviceId),
      body: {},
    );

    return _parseSingle(res['data']);
  }
}
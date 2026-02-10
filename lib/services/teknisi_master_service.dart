import 'package:http/http.dart' as http;

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/servis_model.dart';

class TeknisiService {
  final ApiClient api;
  TeknisiService({required this.api});

  T _parseSingle<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data is Map<String, dynamic>) return fromJson(data);
    throw Exception('Format data tidak valid');
  }

  List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList();
    }
    return [];
  }

  Future<List<ServisModel>> getTasks() async {
    final res = await api.get(ApiConfig.technicianTasks);
    return _parseList(res['data'], ServisModel.fromMap);
  }

  // optional (kalau kamu butuh set service jadi dikerjakan)
  Future<ServisModel> startService(int serviceId) async {
    final res = await api.post(ApiConfig.technicianStartService(serviceId), body: {});
    return _parseSingle(res['data'], ServisModel.fromMap);
  }

  // 1) mulai item TANPA foto
  Future<ServisModel> startItem(int itemId) async {
    final res = await api.post(ApiConfig.technicianStartItem(itemId), body: {});
    return _parseSingle(res['data'], ServisModel.fromMap);
  }

  Future<List<http.MultipartFile>> _files(String field, List<String> paths) async {
    final out = <http.MultipartFile>[];
    for (final p in paths) {
      out.add(await http.MultipartFile.fromPath(field, p));
    }
    return out;
  }

  // 2) update progress per item (multipart)
  Future<ServisModel> updateItemProgress(
      int itemId, {
        String? diagnosa,
        String? tindakan,
        List<String> fotoSebelum = const [],
        List<String> fotoPengerjaan = const [],
        List<String> fotoSesudah = const [],
      }) async {
    final fields = <String, String>{};
    if (diagnosa != null && diagnosa.trim().isNotEmpty) fields['diagnosa'] = diagnosa.trim();
    if (tindakan != null && tindakan.trim().isNotEmpty) fields['tindakan'] = tindakan.trim();

    final files = <http.MultipartFile>[];
    if (fotoSebelum.isNotEmpty) files.addAll(await _files('foto_sebelum[]', fotoSebelum));
    if (fotoPengerjaan.isNotEmpty) files.addAll(await _files('foto_pengerjaan[]', fotoPengerjaan));
    if (fotoSesudah.isNotEmpty) files.addAll(await _files('foto_sesudah[]', fotoSesudah));

    final res = await api.postMultipart(
      ApiConfig.technicianUpdateItemProgress(itemId),
      fields: fields,
      files: files,
    );

    return _parseSingle(res['data'], ServisModel.fromMap);
  }

  // 3) selesai item
  Future<ServisModel> finishItem(
      int itemId, {
        String? diagnosa,
        String? tindakan,
        List<String> fotoSesudah = const [],
      }) async {
    final fields = <String, String>{};
    if (diagnosa != null && diagnosa.trim().isNotEmpty) fields['diagnosa'] = diagnosa.trim();
    if (tindakan != null && tindakan.trim().isNotEmpty) fields['tindakan'] = tindakan.trim();

    final files = <http.MultipartFile>[];
    if (fotoSesudah.isNotEmpty) files.addAll(await _files('foto_sesudah[]', fotoSesudah));

    final res = await api.postMultipart(
      ApiConfig.technicianFinishItem(itemId),
      fields: fields,
      files: files,
    );

    return _parseSingle(res['data'], ServisModel.fromMap);
  }

  // optional selesai service
  Future<ServisModel> finishService(int serviceId) async {
    final res = await api.post(ApiConfig.technicianFinishService(serviceId), body: {});
    return _parseSingle(res['data'], ServisModel.fromMap);
  }
}

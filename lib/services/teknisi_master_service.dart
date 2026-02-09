import 'dart:convert';
import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/servis_model.dart';

class TeknisiService {
  final ApiClient api;
  TeknisiService({required this.api});

  // ===== HELPER METHODS (persis pola owner) =====
  List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data == null) return [];
    if (data is List) {
      return data
          .where((item) => item is Map<String, dynamic>)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  T _parseSingle<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data is Map<String, dynamic>) return fromJson(data);
    throw Exception('Format data tidak valid');
  }

  // ===== TEKNISI: TASKS =====
  Future<List<ServisModel>> getTasks() async {
    try {
      print('🔧 TeknisiService.getTasks() - Memanggil API');
      final res = await api.get(ApiConfig.technicianTasks);

      final data = res['data'] as List? ?? [];
      if (data.isNotEmpty) {
        print('   Sample task: ${jsonEncode(data.first)}');
      }

      final result = _parseList(data, ServisModel.fromMap);
      print('   Parsed ${result.length} tasks');
      return result;
    } catch (e) {
      print('❌ Error in getTasks: $e');
      rethrow;
    }
  }

  Future<ServisModel> startWork(int id) async {
    try {
      print('🚀 TeknisiService.startWork($id)');
      final res = await api.post(ApiConfig.technicianStartWork(id));
      return _parseSingle(res['data'], ServisModel.fromMap);
    } catch (e) {
      print('❌ Error in startWork: $e');
      rethrow;
    }
  }

  Future<ServisModel> completeWork(
      int id, {
        String? diagnosa,
        required List<String> tindakan,
        String? catatan,
        num? biayaServisRekomendasi,
        num? biayaSukuCadangRekomendasi,
      }) async {
    try {
      print('✅ TeknisiService.completeWork($id)');
      final body = <String, dynamic>{
        'tindakan': tindakan,
        if (diagnosa != null && diagnosa.isNotEmpty) 'diagnosa': diagnosa,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
        if (biayaServisRekomendasi != null) 'biaya_servis_rekomendasi': biayaServisRekomendasi,
        if (biayaSukuCadangRekomendasi != null)
          'biaya_suku_cadang_rekomendasi': biayaSukuCadangRekomendasi,
      };

      final res = await api.post(
        ApiConfig.technicianCompleteWork(id),
        body: body,
      );

      return _parseSingle(res['data'], ServisModel.fromMap);
    } catch (e) {
      print('❌ Error in completeWork: $e');
      rethrow;
    }
  }
}

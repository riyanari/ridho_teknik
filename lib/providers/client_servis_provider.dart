import 'package:flutter/material.dart';
import '../models/servis_model.dart';
import '../services/client_servis_service.dart';

class ClientServisProvider extends ChangeNotifier {
  final ClientServisService service;

  ClientServisProvider({required this.service});

  List<ServisModel> servisList = [];
  bool loading = false;
  String? error;

  Future<void> fetchServis({String? acId}) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final data = await service.getServis();
      servisList = data.map((e) => ServisModel.fromMap(e)).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<ServisModel> getServisDetail(int id) async {
    loading = true;
    notifyListeners();

    try {
      final response = await service.getServisDetail(id);

      // Cek struktur response
      if (response['data'] == null) {
        throw Exception('Data tidak ditemukan dalam response');
      }

      final data = response['data'];

      // Debugging
      print('Response data type: ${data.runtimeType}');
      print('Response data: $data');

      return ServisModel.fromMap(data);
    } catch (e) {
      error = 'Gagal mengambil detail servis: ${e.toString()}';
      print('Error in getServisDetail: $e');
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Helper methods
  List<ServisModel> getServisByAc(String acId) {
    return servisList.where((s) => s.acId == acId).toList();
  }

  List<ServisModel> getServisByStatus(ServisStatus status) {
    return servisList.where((s) => s.status == status).toList();
  }

  List<ServisModel> getActiveServis() {
    return servisList.where((s) =>
    s.status != ServisStatus.selesai &&
        s.status != ServisStatus.ditolak
    ).toList();
  }
}
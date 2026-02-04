import 'package:flutter/material.dart';
import '../models/keluhan_model.dart';
import '../services/client_keluhan_service.dart';

class ClientKeluhanProvider extends ChangeNotifier {
  final ClientKeluhanService service;

  ClientKeluhanProvider({required this.service});

  List<KeluhanModel> keluhanList = [];
  bool loading = false;
  String? error;

  Future<void> fetchKeluhan() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final data = await service.getKeluhan();
      keluhanList = data.map((e) => KeluhanModel.fromMap(e)).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> createKeluhan(Map<String, dynamic> body) async {
    loading = true;
    notifyListeners();

    try {
      final result = await service.createKeluhan(body);
      // Tambahkan keluhan baru ke list
      final newKeluhan = KeluhanModel.fromMap(result['data']);
      keluhanList.insert(0, newKeluhan);
    } catch (e) {
      error = e.toString();
      rethrow; // Biarkan UI handle error
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Helper method untuk filter
  List<KeluhanModel> getKeluhanByLokasi(String lokasiId) {
    return keluhanList.where((k) => k.lokasiId == lokasiId).toList();
  }

  List<KeluhanModel> getKeluhanByAc(String acId) {
    return keluhanList.where((k) => k.acId == acId).toList();
  }
}
// lib/providers/client_servis_provider.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ridho_teknik/models/servis_model.dart';
import 'package:ridho_teknik/services/client_servis_service.dart';

class ClientServisProvider extends ChangeNotifier {
  final ClientServisService service;

  ClientServisProvider({required this.service});

  // State untuk list servis
  List<ServisModel> servisList = [];
  bool loading = false;
  String? error;

  // State untuk request cuci
  bool submittingCuci = false;
  String? submitError;

  bool submittingPerbaikan = false;
  String? submitPerbaikanError;

  Future<void> fetchServis({String? acId, String? lokasiId}) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      print('=== FETCHING SERVIS ===');
      print('acId: $acId, lokasiId: $lokasiId');

      final data = await service.getServis(acId: acId, lokasiId: lokasiId);

      print('Data received from service: ${data.length} items');

      if (data.isNotEmpty) {
        print('First item structure: ${data.first.keys}');
        print('First item data: ${data.first}');
      }

      // Parse data ke ServisModel
      servisList = data.map((e) {
        try {
          final servis = ServisModel.fromMap(e);
          print('Successfully parsed servis ID: ${servis.id}');
          return servis;
        } catch (e, stackTrace) {
          print('Error parsing servis data: $e');
          print('Stack trace: $stackTrace');
          print('Problematic data: $e');
          rethrow;
        }
      }).toList();

      print('Total servis parsed: ${servisList.length}');

    } catch (e, stackTrace) {
      error = 'Gagal mengambil data servis: ${e.toString()}';
      print('Error in fetchServis: $e');
      print('Stack trace: $stackTrace');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // METHOD BARU: Request Cuci AC
  // lib/providers/client_servis_provider.dart
  Future<Map<String, dynamic>> requestCuci({
    required dynamic locationId,
    required bool semuaAc,
    List<dynamic>? acUnits,
    String? catatan,
    String? tanggalBerkunjung, // Tambahkan parameter
  }) async {
    submittingCuci = true;
    submitError = null;
    notifyListeners();

    try {
      print('=== REQUEST CUCI FROM PROVIDER ===');

      // Konversi locationId ke int jika perlu
      final int locationIdInt;
      if (locationId is String) {
        locationIdInt = int.parse(locationId);
      } else if (locationId is int) {
        locationIdInt = locationId;
      } else {
        throw Exception('locationId harus String atau int');
      }

      // Konversi acUnits ke List<int> jika perlu
      List<int>? acUnitsInt;
      if (acUnits != null && acUnits.isNotEmpty) {
        acUnitsInt = acUnits.map((unit) {
          if (unit is String) {
            return int.parse(unit);
          } else if (unit is int) {
            return unit;
          } else {
            throw Exception('acUnits harus List<String> atau List<int>');
          }
        }).toList();
      }

      print('Location ID: $locationIdInt');
      print('Semua AC: $semuaAc');
      print('AC Units: $acUnitsInt');
      print('Catatan: $catatan');
      print('Tanggal Berkunjung: $tanggalBerkunjung');

      // Panggil service dengan tanggal_berkunjung
      final response = await service.requestCuci(
        locationId: locationIdInt,
        semuaAc: semuaAc,
        acUnits: acUnitsInt,
        catatan: catatan,
        tanggalBerkunjung: tanggalBerkunjung, // Kirim ke service
      );

      print('Response received in provider: $response');

      // Tambahkan ke list servis jika berhasil
      try {
        final newServis = ServisModel.fromMap(response);
        servisList.insert(0, newServis); // Tambahkan di awal list
      } catch (e) {
        print('Warning: Failed to parse new servis: $e');
      }

      // Reset state
      submittingCuci = false;
      notifyListeners();

      return response;

    } catch (e) {
      submitError = 'Gagal mengirim request cuci: ${e.toString()}';
      submittingCuci = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> requestPerbaikan({
    required dynamic locationId,
    required dynamic acUnitId,
    required String keluhan,
    required String priority,
    List<File>? fotoKeluhan,
    String? tanggalBerkunjung,
  }) async {
    submittingPerbaikan = true;
    submitPerbaikanError = null;
    notifyListeners();

    try {
      print('=== REQUEST PERBAIKAN FROM PROVIDER ===');

      // Konversi locationId dan acUnitId ke int jika perlu
      final int locationIdInt = _parseToInt(locationId);
      final int acUnitIdInt = _parseToInt(acUnitId);

      print('Location ID: $locationIdInt');
      print('AC Unit ID: $acUnitIdInt');
      print('Keluhan: $keluhan');
      print('Priority: $priority');
      print('Foto Keluhan count: ${fotoKeluhan?.length ?? 0}');
      print('Tanggal Berkunjung: $tanggalBerkunjung');

      // Panggil service
      final response = await service.requestPerbaikan(
        locationId: locationIdInt,
        acUnitId: acUnitIdInt,
        keluhan: keluhan,
        priority: priority,
        fotoKeluhan: fotoKeluhan,
        tanggalBerkunjung: tanggalBerkunjung,
      );

      print('Response received in provider: $response');

      // Tambahkan ke list servis jika berhasil
      try {
        final newServis = ServisModel.fromMap(response);
        servisList.insert(0, newServis); // Tambahkan di awal list
      } catch (e) {
        print('Warning: Failed to parse new servis: $e');
      }

      // Reset state
      submittingPerbaikan = false;
      notifyListeners();

      return response;

    } catch (e) {
      submitPerbaikanError = 'Gagal mengirim request perbaikan: ${e.toString()}';
      submittingPerbaikan = false;
      notifyListeners();
      rethrow;
    }
  }

  // Helper method untuk parse ke int
  int _parseToInt(dynamic value) {
    if (value is String) {
      return int.parse(value);
    } else if (value is int) {
      return value;
    } else {
      throw Exception('Value harus String atau int');
    }
  }

  // Clear errors untuk perbaikan
  void clearPerbaikanError() {
    submitPerbaikanError = null;
    notifyListeners();
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

  // Clear errors
  void clearError() {
    error = null;
    notifyListeners();
  }

  void clearSubmitError() {
    submitError = null;
    notifyListeners();
  }
}
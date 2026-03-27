import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/servis_model.dart';
import '../services/client_servis_service.dart';

class ClientServisProvider extends ChangeNotifier {
  final ClientServisService service;

  ClientServisProvider({required this.service});

  List<ServisModel> _servisList = [];
  bool _loading = false;
  String? _error;

  bool _submittingCuci = false;
  String? _submitCuciError;

  bool _submittingPerbaikan = false;
  String? _submitPerbaikanError;

  List<ServisModel> get servisList => _servisList;
  bool get loading => _loading;
  String? get error => _error;

  bool get submittingCuci => _submittingCuci;
  String? get submitCuciError => _submitCuciError;

  bool get submittingPerbaikan => _submittingPerbaikan;
  String? get submitPerbaikanError => _submitPerbaikanError;

  bool get hasData => _servisList.isNotEmpty;
  bool get hasError => _error != null && _error!.isNotEmpty;

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  Future<void> fetchServis({
    int? acId,
    int? lokasiId,
  }) async {
    _error = null;
    _setLoading(true);

    try {
      final result = await service.getServis(
        acId: acId,
        lokasiId: lokasiId,
      );

      _servisList = result;

      if (result.isEmpty) {
        _error = 'Belum ada data servis';
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      if (kDebugMode) {
        debugPrint('❌ fetchServis error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<ServisModel?> requestCuci({
    required dynamic locationId,
    required bool semuaAc,
    List<dynamic>? acUnits,
    String? catatan,
    String? tanggalBerkunjung,
  }) async {
    _submittingCuci = true;
    _submitCuciError = null;
    notifyListeners();

    try {
      final locationIdInt = _parseToInt(locationId);
      final acUnitsInt = _parseToIntList(acUnits);

      final newServis = await service.requestCuci(
        locationId: locationIdInt,
        semuaAc: semuaAc,
        acUnits: acUnitsInt,
        catatan: catatan,
        tanggalBerkunjung: tanggalBerkunjung,
      );

      if (newServis != null) {
        _servisList.insert(0, newServis);
      }

      return newServis;
    } catch (e) {
      _submitCuciError = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _submittingCuci = false;
      notifyListeners();
    }
  }

  Future<ServisModel?> requestPerbaikan({
    required dynamic locationId,
    required dynamic acUnitId,
    required String keluhan,
    required String priority,
    List<File>? fotoKeluhan,
    String? tanggalBerkunjung,
  }) async {
    _submittingPerbaikan = true;
    _submitPerbaikanError = null;
    notifyListeners();

    try {
      final locationIdInt = _parseToInt(locationId);
      final acUnitIdInt = _parseToInt(acUnitId);

      final newServis = await service.requestPerbaikan(
        locationId: locationIdInt,
        acUnitId: acUnitIdInt,
        keluhan: keluhan,
        priority: priority,
        fotoKeluhan: fotoKeluhan,
        tanggalBerkunjung: tanggalBerkunjung,
      );

      if (newServis != null) {
        _servisList.insert(0, newServis);
      }

      return newServis;
    } catch (e) {
      _submitPerbaikanError = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _submittingPerbaikan = false;
      notifyListeners();
    }
  }

  int _parseToInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    throw Exception('Value harus String atau int');
  }

  List<int>? _parseToIntList(List<dynamic>? values) {
    if (values == null || values.isEmpty) return null;

    return values.map((value) {
      if (value is int) return value;
      if (value is String) return int.parse(value);
      throw Exception('Isi list harus String atau int');
    }).toList();
  }

  List<ServisModel> getServisByStatus(ServisStatus status) {
    return _servisList.where((s) => s.status == status).toList();
  }

  List<ServisModel> getActiveServis() {
    return _servisList.where((s) {
      return s.status != ServisStatus.selesai &&
          s.status != ServisStatus.batal;
    }).toList();
  }

  List<ServisModel> getServisByLocation(int lokasiId) {
    return _servisList.where((s) => s.locationId == lokasiId).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSubmitCuciError() {
    _submitCuciError = null;
    notifyListeners();
  }

  void clearSubmitPerbaikanError() {
    _submitPerbaikanError = null;
    notifyListeners();
  }

  void clearData() {
    _servisList = [];
    _error = null;
    _submitCuciError = null;
    _submitPerbaikanError = null;
    notifyListeners();
  }
}
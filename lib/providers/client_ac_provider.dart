import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/ac_model.dart';
import '../services/client_master_service.dart';

class ClientAcProvider extends ChangeNotifier {
  ClientAcProvider({required this.service});

  final ClientMasterService service;

  bool _loading = false;
  String? _error;
  List<AcModel> _ac = [];
  int? _selectedLocationId;

  bool get loading => _loading;
  String? get error => _error;
  List<AcModel> get ac => _ac;
  int? get selectedLocationId => _selectedLocationId;

  bool get hasData => _ac.isNotEmpty;
  bool get hasError => _error != null && _error!.isNotEmpty;
  int get totalAc => _ac.length;

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  Future<void> fetchAc({required int locationId}) async {
    _error = null;
    _selectedLocationId = locationId;
    _setLoading(true);

    try {
      final result = await service.getAc(locationId: locationId);
      _ac = result;

      if (result.isEmpty) {
        _error = 'Belum ada data AC';
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      if (kDebugMode) {
        debugPrint('❌ fetchAc error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearData() {
    _ac = [];
    _selectedLocationId = null;
    _error = null;
    notifyListeners();
  }
}
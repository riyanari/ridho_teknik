import 'package:flutter/foundation.dart';

import '../models/ac_model.dart';
import '../services/ac_unit_service.dart';

class AcUnitProvider with ChangeNotifier {
  final AcUnitService service;

  AcUnitProvider({required this.service});

  List<AcModel> _acUnits = [];
  bool _isLoading = false;
  String? _error;
  AcModel? _selectedAcUnit;
  int? _filterLocationId;

  // ===== GETTERS =====
  List<AcModel> get acUnits => _acUnits;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AcModel? get selectedAcUnit => _selectedAcUnit;
  int? get filterLocationId => _filterLocationId;

  bool get hasData => _acUnits.isNotEmpty;
  bool get hasError => _error != null && _error!.isNotEmpty;
  int get totalAcUnits => _acUnits.length;

  // ===== INTERNAL =====
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ===== FILTER =====
  List<AcModel> getAcUnitsByLocation(int locationId) {
    return _acUnits
        .where((ac) => ac.locationId == locationId)
        .toList();
  }

  // ===== FETCH LIST =====
  Future<void> fetchAcUnits({int? locationId}) async {
    _error = null;
    _filterLocationId = locationId;
    _setLoading(true);

    try {
      final result = await service.getAcUnits(locationId: locationId);
      _acUnits = result;

      if (result.isEmpty) {
        _error = 'Belum ada data AC';
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');

      if (kDebugMode) {
        debugPrint('❌ fetchAcUnits error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // ===== FETCH DETAIL =====
  Future<void> fetchAcUnitDetail(int id) async {
    _error = null;
    _setLoading(true);

    try {
      final result = await service.getAcUnitDetail(id);
      _selectedAcUnit = result;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');

      if (kDebugMode) {
        debugPrint('❌ fetchAcUnitDetail error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // ===== STATE =====
  void selectAcUnit(AcModel ac) {
    _selectedAcUnit = ac;
    notifyListeners();
  }

  void clearSelectedAcUnit() {
    _selectedAcUnit = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearData() {
    _acUnits = [];
    _selectedAcUnit = null;
    _filterLocationId = null;
    _error = null;
    notifyListeners();
  }
}
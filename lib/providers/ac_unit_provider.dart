// providers/ac_unit_provider.dart
import 'package:flutter/foundation.dart';
import '../models/ac_model.dart';
import '../services/ac_unit_service.dart';

class AcUnitProvider with ChangeNotifier {
  final AcUnitService service;

  List<AcModel> _acUnits = [];
  bool _isLoading = false;
  String _error = '';
  AcModel? _selectedAcUnit;
  int? _filterLocationId;

  AcUnitProvider({required this.service});

  List<AcModel> get acUnits => _acUnits;
  bool get isLoading => _isLoading;
  String get error => _error;
  AcModel? get selectedAcUnit => _selectedAcUnit;
  int? get filterLocationId => _filterLocationId;

  List<AcModel> getAcUnitsByLocation(int locationId) {
    return _acUnits.where((ac) => ac.lokasiId == locationId.toString()).toList();
  }

  Future<void> fetchAcUnits({int? locationId}) async {
    try {
      _isLoading = true;
      _error = '';
      _filterLocationId = locationId;
      notifyListeners();

      _acUnits = await service.getAcUnits(locationId: locationId);

      if (_acUnits.isEmpty) {
        _error = 'Belum ada data AC';
      }
    } catch (e) {
      _error = 'Gagal mengambil data AC: ${e.toString()}';
      if (kDebugMode) {
        print('Error fetching AC units: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAcUnitDetail(int id) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      _selectedAcUnit = await service.getAcUnitDetail(id);
    } catch (e) {
      _error = 'Gagal mengambil detail AC: ${e.toString()}';
      if (kDebugMode) {
        print('Error fetching AC unit detail: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  void clearSelectedAcUnit() {
    _selectedAcUnit = null;
    notifyListeners();
  }
}
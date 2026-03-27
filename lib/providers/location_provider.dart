import 'package:flutter/foundation.dart';

import '../models/lokasi_model.dart';
import '../services/location_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService service;

  LocationProvider({required this.service});

  List<LokasiModel> _locations = [];
  bool _isLoading = false;
  String? _error;
  LokasiModel? _selectedLocation;
  int? _filterUserId;

  List<LokasiModel> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  LokasiModel? get selectedLocation => _selectedLocation;
  int? get filterUserId => _filterUserId;

  bool get hasData => _locations.isNotEmpty;
  bool get hasError => _error != null && _error!.isNotEmpty;
  int get totalLocations => _locations.length;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  List<LokasiModel> getLocationsByClient(int clientId) {
    if (_locations.isEmpty) return <LokasiModel>[];

    return _locations.where((location) {
      return location.users.any((user) => user.id == clientId);
    }).toList();
  }

  int getClientTotalAc(int clientId) {
    return getLocationsByClient(clientId)
        .fold<int>(0, (sum, loc) => sum + loc.jumlahAC);
  }

  Future<void> fetchLocations({int? userId}) async {
    _error = null;
    _filterUserId = userId;
    _setLoading(true);

    try {
      final result = await service.getLocations(userId: userId);
      _locations = result;

      if (result.isEmpty) {
        _error = 'Belum ada data lokasi';
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      if (kDebugMode) {
        debugPrint('❌ fetchLocations error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  void selectLocation(LokasiModel location) {
    _selectedLocation = location;
    notifyListeners();
  }

  void clearSelectedLocation() {
    _selectedLocation = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearData() {
    _locations = [];
    _selectedLocation = null;
    _filterUserId = null;
    _error = null;
    notifyListeners();
  }
}
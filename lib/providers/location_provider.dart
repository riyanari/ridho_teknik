// providers/location_provider.dart
import 'package:flutter/foundation.dart';
import '../models/lokasi_model.dart';
import '../services/location_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService service;

  List<LokasiModel> _locations = [];
  bool _isLoading = false;
  String _error = '';
  LokasiModel? _selectedLocation;
  int? _filterClientId;

  LocationProvider({required this.service});

  List<LokasiModel> get locations => _locations;
  bool get isLoading => _isLoading;
  String get error => _error;
  LokasiModel? get selectedLocation => _selectedLocation;
  int? get filterClientId => _filterClientId;

  List<LokasiModel> getLocationsByClient(int clientId) {
    return _locations.where((loc) => loc.clientId == clientId.toString()).toList();
  }

  int getClientTotalAc(int clientId) {
    return getLocationsByClient(clientId)
        .fold(0, (sum, loc) => sum + loc.jumlahAC);
  }

  Future<void> fetchLocations({int? clientId}) async {
    try {
      _isLoading = true;
      _error = '';
      _filterClientId = clientId;
      notifyListeners();

      _locations = await service.getLocations(clientId: clientId);

      if (_locations.isEmpty) {
        _error = 'Belum ada data lokasi';
      }
    } catch (e) {
      _error = 'Gagal mengambil data lokasi: ${e.toString()}';
      if (kDebugMode) {
        print('Error fetching locations: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Future<void> fetchLocationDetail(int id) async {
  //   try {
  //     _isLoading = true;
  //     _error = '';
  //     notifyListeners();
  //
  //     _selectedLocation = await service.getLocationDetail(id);
  //   } catch (e) {
  //     _error = 'Gagal mengambil detail lokasi: ${e.toString()}';
  //     if (kDebugMode) {
  //       print('Error fetching location detail: $e');
  //     }
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  void clearSelectedLocation() {
    _selectedLocation = null;
    notifyListeners();
  }
}
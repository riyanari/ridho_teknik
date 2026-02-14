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

  // Di LocationProvider class
  // Di LocationProvider class
  List<LokasiModel> getLocationsByClient(int clientId) {
    if (_locations.isEmpty) return [];

    return _locations.where((location) {
      // Cek apakah location.users tidak null dan berisi client dengan id yang sesuai
      if (location.users != null && location.users!.isNotEmpty) {
        return location.users!.any((user) => user.id == clientId);
      }
      return false;
    }).toList();
  }

  int getClientTotalAc(int userId) {
    return getLocationsByClient(userId)
        .fold(0, (sum, loc) => sum + loc.jumlahAC);
  }

  Future<void> fetchLocations({int? userId}) async {
    try {
      _isLoading = true;
      _error = '';
      _filterClientId = userId;
      notifyListeners();

      // Panggil service untuk mengambil lokasi berdasarkan clientId
      _locations = await service.getLocations(userId: userId); // Memanggil API dengan query yang sesuai

      if (_locations.isEmpty) {
        _error = 'Belum ada data lokasi';
      }
      print("Fetched locations: $_locations");
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
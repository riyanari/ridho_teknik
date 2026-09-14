import 'package:flutter/foundation.dart';

import '../models/ac_model.dart';
import '../models/lokasi_model.dart';
import '../services/client_master_service.dart';

class ClientAcProvider extends ChangeNotifier {
  ClientAcProvider({
    required this.service,
  });

  final ClientMasterService service;

  // ============================================================
  // AC PER LOKASI
  // Dipakai AcListPage
  // ============================================================

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

  // ============================================================
  // SEMUA AC CLIENT
  // KHUSUS HOME
  // ============================================================

  bool _loadingAll = false;
  String? _allError;

  final List<AcModel> _allAc = [];

  bool get loadingAll => _loadingAll;
  String? get allError => _allError;
  List<AcModel> get allAc => List.unmodifiable(_allAc);

  bool get hasAllData => _allAc.isNotEmpty;

  // ============================================================
  // CACHE PER LOCATION
  // ============================================================

  final Map<int, List<AcModel>> _acByLocation = {};

  Map<int, List<AcModel>> get acByLocation =>
      Map.unmodifiable(_acByLocation);

  List<AcModel> getAcByLocation(
      int locationId,
      ) {
    return List.unmodifiable(
      _acByLocation[locationId] ?? const [],
    );
  }

  // ============================================================
  // FETCH PER LOCATION
  // Dipakai AcListPage
  // ============================================================

  Future<void> fetchAc({
    required int locationId,
  }) async {
    _error = null;
    _selectedLocationId = locationId;

    _loading = true;
    notifyListeners();

    try {
      final result = await service.getAc(
        locationId: locationId,
      );

      _ac = result;

      // simpan juga ke cache
      _acByLocation[locationId] = result;

      if (result.isEmpty) {
        _error = 'Belum ada data AC';
      }
    } catch (e) {
      _error = e
          .toString()
          .replaceFirst(
        'Exception: ',
        '',
      );

      if (kDebugMode) {
        debugPrint(
          '❌ fetchAc error: $e',
        );
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // FETCH SEMUA AC BERDASARKAN DAFTAR LOKASI
  // ============================================================

  Future<void> fetchAllAcByLocations(
      List<LokasiModel> locations,
      ) async {
    _allError = null;
    _loadingAll = true;
    notifyListeners();

    try {
      _allAc.clear();
      _acByLocation.clear();

      final results = await Future.wait(
        locations.map((location) async {
          try {
            final acList = await service.getAc(
              locationId: location.id,
            );

            return MapEntry(
              location.id,
              acList,
            );
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                '⚠️ Gagal mengambil AC lokasi '
                    '${location.id}: $e',
              );
            }

            return MapEntry(
              location.id,
              <AcModel>[],
            );
          }
        }),
      );

      for (final entry in results) {
        _acByLocation[entry.key] =
            entry.value;

        _allAc.addAll(
          entry.value,
        );
      }

      if (kDebugMode) {
        debugPrint(
          '❄️ Total semua AC client: ${_allAc.length}',
        );
      }
    } catch (e) {
      _allError = e
          .toString()
          .replaceFirst(
        'Exception: ',
        '',
      );
    } finally {
      _loadingAll = false;
      notifyListeners();
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshAllAc(
      List<LokasiModel> locations,
      ) async {
    await fetchAllAcByLocations(
      locations,
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearAllError() {
    _allError = null;
    notifyListeners();
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clearData() {
    _ac = [];
    _selectedLocationId = null;
    _error = null;

    notifyListeners();
  }

  void clearAllData() {
    _allAc.clear();
    _acByLocation.clear();
    _allError = null;

    notifyListeners();
  }

  void clearEverything() {
    _ac = [];
    _allAc.clear();
    _acByLocation.clear();

    _selectedLocationId = null;

    _error = null;
    _allError = null;

    notifyListeners();
  }
}
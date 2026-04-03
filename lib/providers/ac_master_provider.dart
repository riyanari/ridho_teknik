import 'package:flutter/foundation.dart';

import '../models/ac_brand_model.dart';
import '../models/ac_capacity_model.dart';
import '../models/ac_series_model.dart';
import '../models/ac_type_model.dart';
import '../services/ac_master_service.dart';

class AcMasterProvider with ChangeNotifier {
  final AcMasterService service;

  AcMasterProvider({required this.service});

  List<AcBrandModel> _brands = [];
  List<AcTypeModel> _types = [];
  List<AcSeriesModel> _series = [];
  List<AcCapacityModel> _capacities = [];

  bool _isLoading = false;
  String? _error;

  int? _selectedBrandId;
  int? _selectedTypeId;
  int? _selectedSeriesId;
  int? _selectedCapacityId;

  List<AcBrandModel> get brands => _brands;
  List<AcTypeModel> get types => _types;
  List<AcSeriesModel> get series => _series;
  List<AcCapacityModel> get capacities => _capacities;

  bool get isLoading => _isLoading;
  String? get error => _error;

  int? get selectedBrandId => _selectedBrandId;
  int? get selectedTypeId => _selectedTypeId;
  int? get selectedSeriesId => _selectedSeriesId;
  int? get selectedCapacityId => _selectedCapacityId;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchFormOptions({
    int? brandId,
    int? typeId,
  }) async {
    _error = null;
    _setLoading(true);

    try {
      final result = await service.getFormOptions(
        brandId: brandId,
        typeId: typeId,
      );

      _brands = result.brands;
      _types = result.types;
      _series = result.series;
      _capacities = result.capacities;

      _selectedBrandId = brandId;
      _selectedTypeId = typeId;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      if (kDebugMode) {
        debugPrint('❌ fetchFormOptions error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchBrands() async {
    _error = null;
    _setLoading(true);

    try {
      _brands = await service.getBrands();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      if (kDebugMode) {
        debugPrint('❌ fetchBrands error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTypes({int? brandId}) async {
    _error = null;
    _setLoading(true);

    try {
      _types = await service.getTypes(brandId: brandId);
      _selectedBrandId = brandId;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      if (kDebugMode) {
        debugPrint('❌ fetchTypes error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchSeries({
    required int brandId,
    int? typeId,
  }) async {
    _error = null;
    _setLoading(true);

    try {
      _series = await service.getSeries(
        brandId: brandId,
        typeId: typeId,
      );
      _selectedBrandId = brandId;
      _selectedTypeId = typeId;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      if (kDebugMode) {
        debugPrint('❌ fetchSeries error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchCapacities({
    int? brandId,
    int? typeId,
  }) async {
    _error = null;
    _setLoading(true);

    try {
      _capacities = await service.getCapacities(
        brandId: brandId,
        typeId: typeId,
      );
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      if (kDebugMode) {
        debugPrint('❌ fetchCapacities error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  void setSelectedBrand(int? value) {
    _selectedBrandId = value;
    _selectedTypeId = null;
    _selectedSeriesId = null;
    _selectedCapacityId = null;

    _types = [];
    _series = [];
    _capacities = [];

    notifyListeners();
  }

  void setSelectedType(int? value) {
    _selectedTypeId = value;
    _selectedSeriesId = null;
    _selectedCapacityId = null;

    _series = [];
    _capacities = [];

    notifyListeners();
  }

  void setSelectedSeries(int? value) {
    _selectedSeriesId = value;
    notifyListeners();
  }

  void setSelectedCapacity(int? value) {
    _selectedCapacityId = value;
    notifyListeners();
  }

  AcBrandModel? get selectedBrand {
    if (_selectedBrandId == null) return null;
    try {
      return _brands.firstWhere((e) => e.id == _selectedBrandId);
    } catch (_) {
      return null;
    }
  }

  AcTypeModel? get selectedType {
    if (_selectedTypeId == null) return null;
    try {
      return _types.firstWhere((e) => e.id == _selectedTypeId);
    } catch (_) {
      return null;
    }
  }

  AcSeriesModel? get selectedSeries {
    if (_selectedSeriesId == null) return null;
    try {
      return _series.firstWhere((e) => e.id == _selectedSeriesId);
    } catch (_) {
      return null;
    }
  }

  AcCapacityModel? get selectedCapacity {
    if (_selectedCapacityId == null) return null;
    try {
      return _capacities.firstWhere((e) => e.id == _selectedCapacityId);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearData() {
    _brands = [];
    _types = [];
    _series = [];
    _capacities = [];

    _selectedBrandId = null;
    _selectedTypeId = null;
    _selectedSeriesId = null;
    _selectedCapacityId = null;

    _error = null;
    notifyListeners();
  }
}
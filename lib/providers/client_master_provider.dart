import 'package:flutter/foundation.dart';

import '../models/lokasi_model.dart';
import '../services/client_master_service.dart';

class ClientMasterProvider with ChangeNotifier {
  ClientMasterProvider({required this.service});

  final ClientMasterService service;

  bool _loading = false;
  String? _error;
  List<LokasiModel> _lokasi = [];

  bool get loading => _loading;
  String? get error => _error;
  List<LokasiModel> get lokasi => _lokasi;

  bool get hasData => _lokasi.isNotEmpty;
  bool get hasError => _error != null && _error!.isNotEmpty;

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  Future<void> fetchLokasi() async {
    _error = null;
    _setLoading(true);

    try {
      final result = await service.getLokasi();
      _lokasi = result;

      if (result.isEmpty) {
        _error = 'Belum ada data lokasi';
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      if (kDebugMode) {
        debugPrint('❌ fetchLokasi error: $e');
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
    _lokasi = [];
    _error = null;
    notifyListeners();
  }
}
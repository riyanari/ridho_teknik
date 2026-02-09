import 'package:flutter/foundation.dart';
import '../models/servis_model.dart';
import '../services/teknisi_master_service.dart';

class TeknisiProvider with ChangeNotifier {
  final TeknisiService service;
  TeknisiProvider({required this.service});

  bool _loading = false;
  bool _submitting = false;

  String? _error;
  String? _submitError;

  List<ServisModel> _tasks = [];
  int _fetchToken = 0;

  bool get loading => _loading;
  bool get submitting => _submitting;

  String? get error => _error;
  String? get submitError => _submitError;

  List<ServisModel> get tasks => _tasks;

  Future<void> fetchTasks() async {
    _loading = true;
    _error = null;
    notifyListeners();

    final int token = ++_fetchToken;

    try {
      final rows = await service.getTasks();
      if (token != _fetchToken) return;

      _tasks = rows;
    } catch (e) {
      if (token != _fetchToken) return;
      _error = 'Gagal mengambil tugas: ${e.toString()}';
      if (kDebugMode) print('❌ fetchTasks error: $e');
    } finally {
      if (token != _fetchToken) return;
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> startWork(int serviceId) async {
    _submitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final updated = await service.startWork(serviceId);

      // update local list
      final idx = _tasks.indexWhere((e) => e.id == serviceId);
      if (idx != -1) _tasks[idx] = updated;

      return true;
    } catch (e) {
      _submitError = 'Gagal memulai pekerjaan: ${e.toString()}';
      if (kDebugMode) print('❌ startWork error: $e');
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<bool> completeWork(
      int serviceId, {
        String? diagnosa,
        required List<String> tindakan,
        String? catatan,
        num? biayaServisRekomendasi,
        num? biayaSukuCadangRekomendasi,
      }) async {
    _submitting = true;
    _submitError = null;
    notifyListeners();

    try {
      await service.completeWork(
        serviceId,
        diagnosa: diagnosa,
        tindakan: tindakan,
        catatan: catatan,
        biayaServisRekomendasi: biayaServisRekomendasi,
        biayaSukuCadangRekomendasi: biayaSukuCadangRekomendasi,
      );

      // paling aman: refresh, karena setelah selesai bisa hilang dari endpoint tugas
      await fetchTasks();
      return true;
    } catch (e) {
      _submitError = 'Gagal menyelesaikan pekerjaan: ${e.toString()}';
      if (kDebugMode) print('❌ completeWork error: $e');
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  void clearErrors() {
    _error = null;
    _submitError = null;
    notifyListeners();
  }

  void clearData() {
    _tasks.clear();
    _error = null;
    _submitError = null;
    notifyListeners();
  }
}

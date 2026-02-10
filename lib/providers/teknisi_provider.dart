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

  // ===== Helpers =====
  void _setSubmitting(bool v) {
    _submitting = v;
    notifyListeners();
  }

  void _setSubmitError(String? msg) {
    _submitError = msg;
    notifyListeners();
  }

  void _replaceTaskByServiceId(ServisModel updated) {
    // NOTE: pastikan ServisModel.id kamu bertipe String/Int konsisten
    final idx = _tasks.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      _tasks[idx] = updated;
    } else {
      // kalau service tidak ada di list (misal berubah status dan endpoint tugas beda),
      // boleh push atau abaikan. Aku pilih push biar UI update.
      _tasks.insert(0, updated);
    }
    notifyListeners();
  }

  // ===== Fetch Tasks =====
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

  // ===== OPTIONAL: start service =====
  Future<bool> startService(int serviceId) async {
    _setSubmitting(true);
    _setSubmitError(null);

    try {
      final updated = await service.startService(serviceId);
      _replaceTaskByServiceId(updated);
      return true;
    } catch (e) {
      _setSubmitError('Gagal mulai servis: ${e.toString()}');
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  // ===== 1) Mulai per ITEM (tanpa foto) =====
  Future<bool> startItem(int itemId) async {
    _setSubmitting(true);
    _setSubmitError(null);

    try {
      final updated = await service.startItem(itemId);
      _replaceTaskByServiceId(updated);
      return true;
    } catch (e) {
      _setSubmitError('Gagal mulai item: ${e.toString()}');
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  // ===== 2) Update progress per ITEM (multipart) =====
  Future<bool> updateItemProgress(
      int itemId, {
        String? diagnosa,
        String? tindakan, // string (kalau array/json, bilang ya nanti aku ubah)
        List<String> fotoSebelum = const [],
        List<String> fotoPengerjaan = const [],
        List<String> fotoSesudah = const [],
      }) async {
    _setSubmitting(true);
    _setSubmitError(null);

    try {
      final updated = await service.updateItemProgress(
        itemId,
        diagnosa: diagnosa,
        tindakan: tindakan,
        fotoSebelum: fotoSebelum,
        fotoPengerjaan: fotoPengerjaan,
        fotoSesudah: fotoSesudah,
      );

      _replaceTaskByServiceId(updated);
      return true;
    } catch (e) {
      _setSubmitError('Gagal update progress: ${e.toString()}');
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  // ===== 3) Selesaikan per ITEM =====
  Future<bool> finishItem(
      int itemId, {
        String? diagnosa,
        String? tindakan,
        List<String> fotoSesudah = const [],
      }) async {
    _setSubmitting(true);
    _setSubmitError(null);

    try {
      final updated = await service.finishItem(
        itemId,
        diagnosa: diagnosa,
        tindakan: tindakan,
        fotoSesudah: fotoSesudah,
      );

      _replaceTaskByServiceId(updated);

      // paling aman: refresh karena item selesai bisa membuat service pindah/hilang dari endpoint tugas
      await fetchTasks();
      return true;
    } catch (e) {
      _setSubmitError('Gagal menyelesaikan item: ${e.toString()}');
      if (kDebugMode) print('❌ finishItem error: $e');
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  // ===== OPTIONAL: finish service =====
  Future<bool> finishService(int serviceId) async {
    _setSubmitting(true);
    _setSubmitError(null);

    try {
      final updated = await service.finishService(serviceId);
      _replaceTaskByServiceId(updated);
      await fetchTasks();
      return true;
    } catch (e) {
      _setSubmitError('Gagal menyelesaikan servis: ${e.toString()}');
      return false;
    } finally {
      _setSubmitting(false);
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

import 'package:flutter/material.dart';
import '../models/lokasi_model.dart';
import '../services/client_master_service.dart';

class ClientMasterProvider extends ChangeNotifier {
  ClientMasterProvider({required this.service});
  final ClientMasterService service;

  bool loading = false;
  String? error;

  List<LokasiModel> lokasi = [];


  Future<void> fetchLokasi() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final rows = await service.getLokasi();

      lokasi = rows.map((e) {
        // mapping field dari API Laravel kamu:
        // Location model: id, name, address, jumlah_ac, last_service
        // plus: ac_count (from withCount)
        final id = (e['id'] ?? '').toString();
        final nama = (e['name'] ?? '').toString();
        final alamat = (e['address'] ?? '').toString();
        final client_id = (e['client_id'] ?? '').toString();

        final jumlahAc = (e['jumlah_ac'] ?? e['ac_count'] ?? 0);
        final last = e['last_service'];

        DateTime? lastService;
        if (last != null && last.toString().isNotEmpty) {
          lastService = DateTime.tryParse(last.toString());
        }

        return LokasiModel(
          id: id,
          nama: nama,
          alamat: alamat,
          jumlahAC: (jumlahAc is int) ? jumlahAc : int.tryParse(jumlahAc.toString()) ?? 0,
          lastService: lastService ?? DateTime.now(),
          clientId: client_id,
        );
      }).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

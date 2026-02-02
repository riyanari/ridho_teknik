import 'package:flutter/material.dart';
import '../models/ac_model.dart';
import '../services/client_master_service.dart';

class ClientAcProvider extends ChangeNotifier {
  ClientAcProvider({required this.service});
  final ClientMasterService service;

  bool loading = false;
  String? error;
  List<AcModel> ac = [];

  Future<void> fetchAc({required int locationId}) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final rows = await service.getAc(locationId: locationId);

      ac = rows.map((e) {
        final id = (e['id'] ?? '').toString();
        final lokasiId = (e['location_id'] ?? '').toString();
        final nama = (e['name'] ?? '').toString();
        final merk = (e['brand'] ?? '').toString();
        final type = (e['type'] ?? '').toString();
        final kapasitas = (e['capacity'] ?? '').toString();

        final last = e['last_service'];
        final lastService = (last != null && last.toString().isNotEmpty)
            ? DateTime.tryParse(last.toString()) ?? DateTime.now()
            : DateTime.now();

        return AcModel(
          id: id,
          lokasiId: lokasiId,
          nama: nama,
          merk: merk,
          type: type,
          kapasitas: kapasitas,
          terakhirService: lastService,
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

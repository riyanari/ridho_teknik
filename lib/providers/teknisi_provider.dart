import 'package:flutter/material.dart';
import 'package:ridho_teknik/services/teknisi_service.dart';

import '../models/keluhan_model.dart';
import '../models/servis_model.dart';
import '../models/teknisi_model.dart';

class TeknisiProvider with ChangeNotifier {
  final TeknisiService service;

  TeknisiProvider({required this.service});

  bool isLoading = false;
  String? error;

  TeknisiModel? teknisi;
  List<ServisModel> servisAktif = [];
  List<KeluhanModel> keluhanAktif = [];

  int totalTugas = 0;
  int tugasBerjalan = 0;
  int menungguKonfirmasi = 0;
  int tugasSelesai = 0;

  Future<void> fetch() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final json = await service.fetchDashboard();
      final data = (json['data'] ?? {}) as Map<String, dynamic>;

      teknisi = TeknisiModel(
        id: (data['teknisi']?['id'] ?? '').toString(),
        nama: (data['teknisi']?['nama'] ?? '').toString(),
        spesialisasi: (data['teknisi']?['spesialisasi'] ?? '').toString(),
        noHp: (data['teknisi']?['noHp'] ?? '').toString(),
        rating: (data['teknisi']?['rating'] ?? 0).toDouble(),
        totalService: (data['teknisi']?['totalService'] ?? 0) as int,
        foto: (data['teknisi']?['foto'] ?? '').toString(),
      );

      final stats = (data['stats'] ?? {}) as Map<String, dynamic>;
      totalTugas = (stats['totalTugas'] ?? 0) as int;
      tugasBerjalan = (stats['tugasBerjalan'] ?? 0) as int;
      menungguKonfirmasi = (stats['menungguKonfirmasi'] ?? 0) as int;
      tugasSelesai = (stats['tugasSelesai'] ?? 0) as int;

      final servisArr = (data['servisAktif'] ?? []) as List<dynamic>;
      servisAktif = servisArr
          .map((e) => ServisModel.fromMap(e as Map<String, dynamic>))
          .toList();

      final keluhanArr = (data['keluhanAktif'] ?? []) as List<dynamic>;
      keluhanAktif = keluhanArr
          .map((e) => KeluhanModel(
        id: e['id'].toString(),
        lokasiId: e['lokasiId'].toString(),
        acId: e['acId'].toString(),
        judul: e['judul'].toString(),
        deskripsi: e['deskripsi'].toString(),
        status: KeluhanStatus.values.byName(e['status'].toString()),
        prioritas: Prioritas.values.byName(e['prioritas'].toString()),
        tanggalDiajukan: DateTime.parse(e['tanggalDiajukan'].toString()),
        tanggalSelesai: e['tanggalSelesai'] == null
            ? null
            : DateTime.parse(e['tanggalSelesai'].toString()),
        assignedTo: e['assignedTo']?.toString(),
        catatanServicer: e['catatanServicer']?.toString(),
        fotoKeluhan: (e['fotoKeluhan'] as List<dynamic>? ?? []).cast<String>(),
      ))
          .toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

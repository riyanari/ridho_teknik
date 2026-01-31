// lib/models/keluhan_model.dart
import 'package:flutter/material.dart';
import '../theme/theme.dart'; // Import theme

enum KeluhanStatus { diajukan, dikirim, diproses, selesai, ditolak }
enum Prioritas { rendah, sedang, tinggi, darurat }

class KeluhanModel {
  final String id;
  final String lokasiId;
  final String acId;
  final String judul;
  final String deskripsi;
  final KeluhanStatus status;
  final Prioritas prioritas;
  final DateTime tanggalDiajukan;
  final DateTime? tanggalSelesai;
  final String? assignedTo; // ID servicer/CVRT
  final String? catatanServicer;
  final List<String> fotoKeluhan;

  KeluhanModel({
    required this.id,
    required this.lokasiId,
    required this.acId,
    required this.judul,
    required this.deskripsi,
    this.status = KeluhanStatus.diajukan,
    this.prioritas = Prioritas.sedang,
    required this.tanggalDiajukan,
    this.tanggalSelesai,
    this.assignedTo,
    this.catatanServicer,
    this.fotoKeluhan = const [],
  });

  String get statusText {
    switch (status) {
      case KeluhanStatus.diajukan:
        return 'Diajukan';
      case KeluhanStatus.dikirim:
        return 'Dikirim ke Servicer';
      case KeluhanStatus.diproses:
        return 'Diproses';
      case KeluhanStatus.selesai:
        return 'Selesai';
      case KeluhanStatus.ditolak:
        return 'Ditolak';
    }
  }

  Color get statusColor {
    switch (status) {
      case KeluhanStatus.diajukan:
        return Colors.blue; // atau kPrimaryColor
      case KeluhanStatus.dikirim:
        return Colors.orange; // atau kSecondaryColor
      case KeluhanStatus.diproses:
        return Colors.purple; // atau kBoxMenuDarkBlueColor
      case KeluhanStatus.selesai:
        return kBoxMenuGreenColor; // Hijau untuk selesai
      case KeluhanStatus.ditolak:
        return kBoxMenuRedColor; // Merah untuk ditolak
    }
  }

  String get prioritasText {
    switch (prioritas) {
      case Prioritas.rendah:
        return 'Rendah';
      case Prioritas.sedang:
        return 'Sedang';
      case Prioritas.tinggi:
        return 'Tinggi';
      case Prioritas.darurat:
        return 'Darurat';
    }
  }

  Color get prioritasColor {
    switch (prioritas) {
      case Prioritas.rendah:
        return Colors.green;
      case Prioritas.sedang:
        return Colors.orange;
      case Prioritas.tinggi:
        return Colors.red;
      case Prioritas.darurat:
        return Colors.red[900]!;
    }
  }
}

// Extension untuk menambahkan properti color ke enum KeluhanStatus
extension KeluhanStatusExtension on KeluhanStatus {
  Color get color {
    switch (this) {
      case KeluhanStatus.diajukan:
        return Colors.blue;
      case KeluhanStatus.dikirim:
        return Colors.orange;
      case KeluhanStatus.diproses:
        return Colors.purple;
      case KeluhanStatus.selesai:
        return kBoxMenuGreenColor;
      case KeluhanStatus.ditolak:
        return kBoxMenuRedColor;
    }
  }

  String get text {
    switch (this) {
      case KeluhanStatus.diajukan:
        return 'Diajukan';
      case KeluhanStatus.dikirim:
        return 'Dikirim';
      case KeluhanStatus.diproses:
        return 'Diproses';
      case KeluhanStatus.selesai:
        return 'Selesai';
      case KeluhanStatus.ditolak:
        return 'Ditolak';
    }
  }
}
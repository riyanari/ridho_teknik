// lib/models/keluhan_model.dart
import 'dart:convert';
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

  /// Konversi dari Map (dari API/Firestore) ke KeluhanModel
  factory KeluhanModel.fromMap(Map<String, dynamic> map) {
    return KeluhanModel(
      id: (map['id'] ?? '').toString(),
      lokasiId: (map['lokasi_id'] ?? map['lokasiId'] ?? '').toString(),
      acId: (map['ac_id'] ?? map['acId'] ?? '').toString(),
      judul: (map['judul'] ?? '').toString(),
      deskripsi: (map['deskripsi'] ?? '').toString(),
      status: KeluhanStatus.values.byName(
        (map['status'] ?? 'diajukan').toString(),
      ),
      prioritas: Prioritas.values.byName(
        (map['prioritas'] ?? 'sedang').toString(),
      ),
      tanggalDiajukan: DateTime.parse(map['tanggal_diajukan'] ??
          map['tanggalDiajukan'] ?? DateTime.now().toIso8601String()),
      tanggalSelesai: map['tanggal_selesai'] != null || map['tanggalSelesai'] != null
          ? DateTime.parse((map['tanggal_selesai'] ?? map['tanggalSelesai']).toString())
          : null,
      assignedTo: map['assigned_to']?.toString() ?? map['assignedTo']?.toString(),
      catatanServicer: map['catatan_servicer']?.toString() ?? map['catatanServicer']?.toString(),
      fotoKeluhan: (map['foto_keluhan'] as List<dynamic>? ??
          map['fotoKeluhan'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  /// Konversi dari JSON string ke KeluhanModel
  factory KeluhanModel.fromJson(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return KeluhanModel.fromMap(map);
  }

  /// Konversi ke Map (untuk API/Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lokasi_id': lokasiId,
      'ac_id': acId,
      'judul': judul,
      'deskripsi': deskripsi,
      'status': status.name,
      'prioritas': prioritas.name,
      'tanggal_diajukan': tanggalDiajukan.toIso8601String(),
      'tanggal_selesai': tanggalSelesai?.toIso8601String(),
      'assigned_to': assignedTo,
      'catatan_servicer': catatanServicer,
      'foto_keluhan': fotoKeluhan,
    };
  }

  /// Konversi ke JSON string
  String toJson() => jsonEncode(toMap());

  /// Untuk copy dengan perubahan
  KeluhanModel copyWith({
    String? id,
    String? lokasiId,
    String? acId,
    String? judul,
    String? deskripsi,
    KeluhanStatus? status,
    Prioritas? prioritas,
    DateTime? tanggalDiajukan,
    DateTime? tanggalSelesai,
    String? assignedTo,
    String? catatanServicer,
    List<String>? fotoKeluhan,
  }) {
    return KeluhanModel(
      id: id ?? this.id,
      lokasiId: lokasiId ?? this.lokasiId,
      acId: acId ?? this.acId,
      judul: judul ?? this.judul,
      deskripsi: deskripsi ?? this.deskripsi,
      status: status ?? this.status,
      prioritas: prioritas ?? this.prioritas,
      tanggalDiajukan: tanggalDiajukan ?? this.tanggalDiajukan,
      tanggalSelesai: tanggalSelesai ?? this.tanggalSelesai,
      assignedTo: assignedTo ?? this.assignedTo,
      catatanServicer: catatanServicer ?? this.catatanServicer,
      fotoKeluhan: fotoKeluhan ?? this.fotoKeluhan,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is KeluhanModel &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
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

// Extension untuk Prioritas (opsional)
extension PrioritasExtension on Prioritas {
  Color get color {
    switch (this) {
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

  String get text {
    switch (this) {
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
}
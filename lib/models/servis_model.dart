import 'package:flutter/material.dart';

enum ServisStatus {
  menungguKonfirmasi,
  ditugaskan,
  dikerjakan,
  selesai,
  batal,
}

enum JenisPenanganan {
  cuci,
  perbaikan,
  instalasi,
}

class ServisModel {
  final int id;
  final String? complaintId;
  final int? clientId;
  final int? locationId;
  final int? acUnitId;
  final int? technicianId;

  final List<int> acUnits;
  final int jumlahAc;

  final JenisPenanganan jenis;
  final ServisStatus status;

  final String? tindakanSummary;
  final String? diagnosa;
  final String? catatan;
  final String? keluhanClient;

  final List<String> fotoKeluhan;
  final List<String> fotoSebelum;
  final List<String> fotoPengerjaan;
  final List<String> fotoSesudah;
  final List<String> fotoSukuCadang;

  final DateTime? tanggalBerkunjung;
  final DateTime? tanggalDitugaskan;
  final DateTime? tanggalMulai;
  final DateTime? tanggalSelesai;
  final DateTime? tanggalDikonfirmasiOwner;
  final DateTime? tanggalDikonfirmasiClient;

  final double biayaServis;
  final double biayaSukuCadang;
  final double totalBiaya;
  final String? noInvoice;

  final Map<String, dynamic>? clientData;
  final Map<String, dynamic>? lokasiData;
  final Map<String, dynamic>? acData;
  final Map<String, dynamic>? teknisiData;
  final List<Map<String, dynamic>> techniciansData;
  final List<Map<String, dynamic>> itemsData;

  const ServisModel({
    required this.id,
    this.complaintId,
    this.clientId,
    this.locationId,
    this.acUnitId,
    this.technicianId,
    this.acUnits = const [],
    this.jumlahAc = 0,
    required this.jenis,
    required this.status,
    this.tindakanSummary,
    this.diagnosa,
    this.catatan,
    this.keluhanClient,
    this.fotoKeluhan = const [],
    this.fotoSebelum = const [],
    this.fotoPengerjaan = const [],
    this.fotoSesudah = const [],
    this.fotoSukuCadang = const [],
    this.tanggalBerkunjung,
    this.tanggalDitugaskan,
    this.tanggalMulai,
    this.tanggalSelesai,
    this.tanggalDikonfirmasiOwner,
    this.tanggalDikonfirmasiClient,
    this.biayaServis = 0,
    this.biayaSukuCadang = 0,
    this.totalBiaya = 0,
    this.noInvoice,
    this.clientData,
    this.lokasiData,
    this.acData,
    this.teknisiData,
    this.techniciansData = const [],
    this.itemsData = const [],
  });

  static int? _parseIntNullable(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static List<String> _parseStringList(dynamic v) {
    if (v is List) {
      return v.map((e) => e.toString()).toList();
    }
    return [];
  }

  static List<int> _parseIntList(dynamic v) {
    if (v is List) {
      return v
          .map((e) => int.tryParse(e.toString()))
          .where((e) => e != null)
          .cast<int>()
          .toList();
    }
    return [];
  }

  static Map<String, dynamic>? _parseMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  static List<Map<String, dynamic>> _parseMapList(dynamic v) {
    if (v is List) {
      return v
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }

  static ServisStatus _parseStatus(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'ditugaskan':
        return ServisStatus.ditugaskan;
      case 'dikerjakan':
        return ServisStatus.dikerjakan;
      case 'selesai':
        return ServisStatus.selesai;
      case 'batal':
        return ServisStatus.batal;
      default:
        return ServisStatus.menungguKonfirmasi;
    }
  }

  static JenisPenanganan _parseJenis(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'cuci':
        return JenisPenanganan.cuci;
      case 'instalasi':
        return JenisPenanganan.instalasi;
      default:
        return JenisPenanganan.perbaikan;
    }
  }

  factory ServisModel.fromMap(Map<String, dynamic> map) {
    return ServisModel(
      id: _parseIntNullable(map['id']) ?? 0,
      complaintId: map['complaint_id']?.toString(),
      clientId: _parseIntNullable(map['client_id']),
      locationId: _parseIntNullable(map['location_id']),
      acUnitId: _parseIntNullable(map['ac_unit_id']),
      technicianId: _parseIntNullable(map['technician_id']),
      acUnits: _parseIntList(map['ac_units']),
      jumlahAc: _parseIntNullable(map['jumlah_ac']) ?? 0,
      jenis: _parseJenis(map['jenis']?.toString()),
      status: _parseStatus(map['status']?.toString()),
      tindakanSummary: map['tindakan']?.toString(),
      diagnosa: map['diagnosa']?.toString(),
      catatan: map['catatan']?.toString(),
      keluhanClient: map['keluhan_client']?.toString(),
      fotoKeluhan: _parseStringList(map['foto_keluhan']),
      fotoSebelum: _parseStringList(map['foto_sebelum']),
      fotoPengerjaan: _parseStringList(map['foto_pengerjaan']),
      fotoSesudah: _parseStringList(map['foto_sesudah']),
      fotoSukuCadang: _parseStringList(map['foto_suku_cadang']),
      tanggalBerkunjung: _parseDate(map['tanggal_berkunjung']),
      tanggalDitugaskan: _parseDate(map['tanggal_ditugaskan']),
      tanggalMulai: _parseDate(map['tanggal_mulai']),
      tanggalSelesai: _parseDate(map['tanggal_selesai']),
      tanggalDikonfirmasiOwner: _parseDate(map['tanggal_dikonfirmasi_owner']),
      tanggalDikonfirmasiClient: _parseDate(map['tanggal_dikonfirmasi_client']),
      biayaServis: _parseDouble(map['biaya_servis']),
      biayaSukuCadang: _parseDouble(map['biaya_suku_cadang']),
      totalBiaya: _parseDouble(map['total_biaya']),
      noInvoice: map['no_invoice']?.toString(),
      clientData: _parseMap(map['client']),
      lokasiData: _parseMap(map['lokasi']),
      acData: _parseMap(map['ac']),
      teknisiData: _parseMap(map['teknisi']),
      techniciansData: _parseMapList(map['technicians']),
      itemsData: _parseMapList(map['items']),
    );
  }

  factory ServisModel.fromJson(Map<String, dynamic> json) {
    return ServisModel.fromMap(json);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'complaint_id': complaintId,
      'client_id': clientId,
      'location_id': locationId,
      'ac_unit_id': acUnitId,
      'technician_id': technicianId,
      'ac_units': acUnits,
      'jumlah_ac': jumlahAc,
      'jenis': jenis.name,
      'status': status.name,
      'tindakan': tindakanSummary,
      'diagnosa': diagnosa,
      'catatan': catatan,
      'keluhan_client': keluhanClient,
      'foto_keluhan': fotoKeluhan,
      'foto_sebelum': fotoSebelum,
      'foto_pengerjaan': fotoPengerjaan,
      'foto_sesudah': fotoSesudah,
      'foto_suku_cadang': fotoSukuCadang,
      'tanggal_berkunjung': tanggalBerkunjung?.toIso8601String(),
      'tanggal_ditugaskan': tanggalDitugaskan?.toIso8601String(),
      'tanggal_mulai': tanggalMulai?.toIso8601String(),
      'tanggal_selesai': tanggalSelesai?.toIso8601String(),
      'tanggal_dikonfirmasi_owner':
      tanggalDikonfirmasiOwner?.toIso8601String(),
      'tanggal_dikonfirmasi_client':
      tanggalDikonfirmasiClient?.toIso8601String(),
      'biaya_servis': biayaServis,
      'biaya_suku_cadang': biayaSukuCadang,
      'total_biaya': totalBiaya,
      'no_invoice': noInvoice,
      'client': clientData,
      'lokasi': lokasiData,
      'ac': acData,
      'teknisi': teknisiData,
      'technicians': techniciansData,
      'items': itemsData,
    };
  }

  String get lokasiNama => lokasiData?['name']?.toString() ?? '-';
  String get clientNama => clientData?['name']?.toString() ?? '-';
  String get teknisiNama => teknisiData?['name']?.toString() ?? 'Belum ditugaskan';

  String get statusDisplay {
    switch (status) {
      case ServisStatus.menungguKonfirmasi:
        return 'Menunggu Konfirmasi';
      case ServisStatus.ditugaskan:
        return 'Ditugaskan';
      case ServisStatus.dikerjakan:
        return 'Dikerjakan';
      case ServisStatus.selesai:
        return 'Selesai';
      case ServisStatus.batal:
        return 'Batal';
    }
  }

  String get jenisDisplay {
    switch (jenis) {
      case JenisPenanganan.cuci:
        return 'Cuci';
      case JenisPenanganan.perbaikan:
        return 'Perbaikan';
      case JenisPenanganan.instalasi:
        return 'Instalasi';
    }
  }

  Color get statusColor {
    switch (status) {
      case ServisStatus.menungguKonfirmasi:
        return Colors.orange;
      case ServisStatus.ditugaskan:
        return Colors.blue;
      case ServisStatus.dikerjakan:
        return Colors.purple;
      case ServisStatus.selesai:
        return Colors.green;
      case ServisStatus.batal:
        return Colors.red;
    }
  }
}
import 'package:flutter/material.dart';

enum ServisStatus { menungguKonfirmasi, ditugaskan, dikerjakan, selesai, batal }

enum JenisPenanganan { cuci, perbaikan, instalasi }

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

  // ============================================================
  // PARSER
  // ============================================================

  static int? _parseIntNullable(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  static double _parseDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value
          .where((item) => item != null)
          .map((item) => item.toString())
          .toList();
    }

    return <String>[];
  }

  static List<int> _parseIntList(dynamic value) {
    if (value is! List) {
      return <int>[];
    }

    return value
        .map((item) => int.tryParse(item.toString()))
        .whereType<int>()
        .toList();
  }

  static Map<String, dynamic>? _parseMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  static List<Map<String, dynamic>> _parseMapList(dynamic value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .where((item) => item is Map)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static ServisStatus _parseStatus(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'ditugaskan':
        return ServisStatus.ditugaskan;

      case 'dikerjakan':
        return ServisStatus.dikerjakan;

      case 'selesai':
        return ServisStatus.selesai;

      case 'batal':
        return ServisStatus.batal;

      case 'menunggu_konfirmasi':
      default:
        return ServisStatus.menungguKonfirmasi;
    }
  }

  static JenisPenanganan _parseJenis(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'cuci':
        return JenisPenanganan.cuci;

      case 'instalasi':
        return JenisPenanganan.instalasi;

      case 'perbaikan':
      default:
        return JenisPenanganan.perbaikan;
    }
  }

  // ============================================================
  // FROM MAP
  //
  // Mendukung:
  //
  // 1. Response service langsung
  // {
  //   id: 11,
  //   lokasi: {...}
  // }
  //
  // 2. Response ServiceItem / Upcoming
  // {
  //   id: 101,
  //   service_id: 11,
  //   service: {
  //     id: 11,
  //     lokasi: {...}
  //   },
  //   ac_unit: {...}
  // }
  // ============================================================

  factory ServisModel.fromMap(Map<String, dynamic> map) {
    final wrapper = Map<String, dynamic>.from(map);

    final nestedService = _parseMap(wrapper['service']);

    // Jika response upcoming berupa ServiceItem,
    // kita jadikan nested "service" sebagai sumber utama.
    final source = nestedService != null
        ? Map<String, dynamic>.from(nestedService)
        : Map<String, dynamic>.from(wrapper);

    // ==========================================================
    // MERGE DATA SERVICE ITEM
    // ==========================================================

    if (nestedService != null) {
      // Jadwal pada ServiceItem lebih spesifik.
      if (wrapper['tanggal_berkunjung'] != null) {
        source['tanggal_berkunjung'] = wrapper['tanggal_berkunjung'];
      }

      if (wrapper['tanggal_mulai'] != null) {
        source['tanggal_mulai'] = wrapper['tanggal_mulai'];
      }

      if (wrapper['tanggal_selesai'] != null) {
        source['tanggal_selesai'] = wrapper['tanggal_selesai'];
      }

      if (wrapper['tanggal_dikonfirmasi_owner'] != null) {
        source['tanggal_dikonfirmasi_owner'] =
            wrapper['tanggal_dikonfirmasi_owner'];
      }

      if (wrapper['tanggal_dikonfirmasi_client'] != null) {
        source['tanggal_dikonfirmasi_client'] =
            wrapper['tanggal_dikonfirmasi_client'];
      }

      // Status item dapat digunakan sebagai fallback.
      source['status'] ??= wrapper['status'];

      // AC dari ServiceItem.
      if (source['ac'] == null && wrapper['ac_unit'] != null) {
        source['ac'] = wrapper['ac_unit'];
      }

      // Teknisi dari ServiceItem.
      if (source['teknisi'] == null && wrapper['technician'] != null) {
        source['teknisi'] = wrapper['technician'];
      }

      if (source['technician_id'] == null && wrapper['technician_id'] != null) {
        source['technician_id'] = wrapper['technician_id'];
      }

      if (source['ac_unit_id'] == null && wrapper['ac_unit_id'] != null) {
        source['ac_unit_id'] = wrapper['ac_unit_id'];
      }
    }

    // ==========================================================
    // LOCATION
    // ==========================================================

    final lokasi = _parseMap(source['lokasi']) ?? _parseMap(source['location']);

    // ==========================================================
    // CLIENT
    // ==========================================================

    final client = _parseMap(source['client']) ?? _parseMap(source['user']);

    // ==========================================================
    // AC
    // ==========================================================

    final ac = _parseMap(source['ac']) ?? _parseMap(source['ac_unit']);

    // ==========================================================
    // TECHNICIAN
    // ==========================================================

    final teknisi =
        _parseMap(source['teknisi']) ?? _parseMap(source['technician']);

    return ServisModel(
      // Jika upcoming:
      // source['id'] = service id = 11
      //
      // BUKAN ServiceItem id = 101.
      id:
          _parseIntNullable(source['id']) ??
          _parseIntNullable(wrapper['service_id']) ??
          0,

      complaintId: source['complaint_id']?.toString(),

      clientId: _parseIntNullable(source['client_id']),

      locationId:
          _parseIntNullable(source['location_id']) ??
          _parseIntNullable(lokasi?['id']),

      acUnitId:
          _parseIntNullable(source['ac_unit_id']) ??
          _parseIntNullable(wrapper['ac_unit_id']),

      technicianId:
          _parseIntNullable(source['technician_id']) ??
          _parseIntNullable(wrapper['technician_id']),

      acUnits: _parseIntList(source['ac_units']),

      jumlahAc: _parseIntNullable(source['jumlah_ac']) ?? 0,

      jenis: _parseJenis(source['jenis']?.toString()),

      status: _parseStatus(source['status']?.toString()),

      tindakanSummary: source['tindakan']?.toString(),

      diagnosa: source['diagnosa']?.toString(),

      catatan: source['catatan']?.toString(),

      keluhanClient: source['keluhan_client']?.toString(),

      fotoKeluhan: _parseStringList(source['foto_keluhan']),

      fotoSebelum: _parseStringList(source['foto_sebelum']),

      fotoPengerjaan: _parseStringList(source['foto_pengerjaan']),

      fotoSesudah: _parseStringList(source['foto_sesudah']),

      fotoSukuCadang: _parseStringList(source['foto_suku_cadang']),

      tanggalBerkunjung: _parseDate(source['tanggal_berkunjung']),

      tanggalDitugaskan: _parseDate(source['tanggal_ditugaskan']),

      tanggalMulai: _parseDate(source['tanggal_mulai']),

      tanggalSelesai: _parseDate(source['tanggal_selesai']),

      tanggalDikonfirmasiOwner: _parseDate(
        source['tanggal_dikonfirmasi_owner'],
      ),

      tanggalDikonfirmasiClient: _parseDate(
        source['tanggal_dikonfirmasi_client'],
      ),

      biayaServis: _parseDouble(source['biaya_servis']),

      biayaSukuCadang: _parseDouble(source['biaya_suku_cadang']),

      totalBiaya: _parseDouble(source['total_biaya']),

      noInvoice: source['no_invoice']?.toString(),

      clientData: client,

      lokasiData: lokasi,

      acData: ac,

      teknisiData: teknisi,

      techniciansData: _parseMapList(source['technicians']),

      itemsData: _parseMapList(source['items']),
    );
  }

  factory ServisModel.fromJson(Map<String, dynamic> json) {
    return ServisModel.fromMap(json);
  }

  // ============================================================
  // TO MAP
  // ============================================================

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
      'tanggal_dikonfirmasi_owner': tanggalDikonfirmasiOwner?.toIso8601String(),
      'tanggal_dikonfirmasi_client': tanggalDikonfirmasiClient
          ?.toIso8601String(),
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

  // ============================================================
  // LOCATION
  // ============================================================

  String get lokasiNama {
    final value = (lokasiData?['name'] ?? lokasiData?['nama'] ?? '')
        .toString()
        .trim();

    if (value.isEmpty) {
      return 'Lokasi belum tersedia';
    }

    return value;
  }

  String get lokasiAlamat {
    final value = (lokasiData?['address'] ?? lokasiData?['alamat'] ?? '')
        .toString()
        .trim();

    return value;
  }

  // ============================================================
  // CLIENT
  // ============================================================

  String get clientNama {
    final value = (clientData?['name'] ?? '').toString().trim();

    if (value.isEmpty) {
      return '-';
    }

    return value;
  }

  // ============================================================
  // TECHNICIAN
  // ============================================================

  String get teknisiNama {
    final value = (teknisiData?['name'] ?? '').toString().trim();

    if (value.isEmpty) {
      return 'Belum ditugaskan';
    }

    return value;
  }

  // ============================================================
  // STATUS DISPLAY
  // ============================================================

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

  // ============================================================
  // JENIS DISPLAY
  // ============================================================

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

  // ============================================================
  // STATUS COLOR
  // ============================================================

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

// lib/models/servis_model.dart
import 'dart:convert';
import 'package:flutter/material.dart';

enum ServisStatus {
  menunggu_konfirmasi,
  ditugaskan,
  dikerjakan,
  selesai,
  batal,

  // Status lain untuk kompatibilitas
  dalam_perjalanan,
  tiba_di_lokasi,
  sedang_diperiksa,
  dalam_perbaikan,
  menunggu_suku_cadang,
  ditolak,
  menunggu_konfirmasi_owner,
}

enum TindakanServis {
  pembersihan,
  isiFreon,
  gantiFilter,
  perbaikanKompressor,
  perbaikanPCB,
  gantiKapasitor,
  gantiFanMotor,
  tuneUp,
  lainnya,
}

enum JenisPenanganan {
  cuciAc,
  perbaikanAc,
  instalasi,
}

class ServisModel {
  final String id;
  final String keluhanId;
  final String lokasiId;
  final String acId;

  // SINGLE TECHNICIAN (untuk backward compatibility)
  final String teknisiId;

  // MULTIPLE TECHNICIANS - PENAMBAHAN BARU
  final List<int>? technicianIds;
  final String? technicianIdsJson;

  final int? jumlahAc;
  final JenisPenanganan jenis;
  final ServisStatus status;
  final List<TindakanServis> tindakan;
  final String diagnosa;
  final String catatan;

  final List<String> fotoSebelum;
  final List<String> fotoPengerjaan;
  final List<String> fotoSesudah;
  final List<String> fotoSukuCadang;

  // TANGGAL
  final DateTime? tanggalBerkunjung;
  final DateTime tanggalDitugaskan;
  final DateTime? tanggalMulai;
  final DateTime? tanggalSelesai;
  final DateTime? tanggalDikonfirmasi;

  final double biayaServis;
  final double biayaSukuCadang;
  final String? noInvoice;

  // Data relasional dari API
  final Map<String, dynamic>? lokasiData;
  final Map<String, dynamic>? acData;
  final Map<String, dynamic>? teknisiData;
  final Map<String, dynamic>? keluhanData;
  // MULTIPLE TECHNICIANS DETAIL DARI API (nama, pivot, dll)
  final List<Map<String, dynamic>> techniciansData;


  const ServisModel({
    required this.id,
    required this.keluhanId,
    required this.lokasiId,
    required this.acId,
    required this.teknisiId,

    // PENAMBAHAN BARU
    this.technicianIds,
    this.technicianIdsJson,

    this.jumlahAc,
    this.jenis = JenisPenanganan.perbaikanAc,
    this.status = ServisStatus.menunggu_konfirmasi,
    this.tindakan = const [],
    this.diagnosa = '',
    this.catatan = '',
    this.fotoSebelum = const [],
    this.fotoPengerjaan = const [],
    this.fotoSesudah = const [],
    this.fotoSukuCadang = const [],
    this.tanggalBerkunjung,
    required this.tanggalDitugaskan,
    this.tanggalMulai,
    this.tanggalSelesai,
    this.tanggalDikonfirmasi,
    this.biayaServis = 0,
    this.biayaSukuCadang = 0,
    this.noInvoice,

    this.lokasiData,
    this.acData,
    this.teknisiData,
    this.keluhanData,

    this.techniciansData = const [],
  });

  double get totalBiaya => biayaServis + biayaSukuCadang;

  // ===== MULTIPLE TECHNICIANS GETTERS =====

  /// Get semua technician IDs (dari multiple atau single)
  List<int> get allTechnicianIds {
    if (technicianIds != null && technicianIds!.isNotEmpty) {
      return technicianIds!;
    }
    // Fallback ke teknisiId lama jika ada
    if (teknisiId.isNotEmpty) {
      final id = int.tryParse(teknisiId);
      if (id != null) {
        return [id];
      }
    }
    return [];
  }

  /// Cek apakah teknisi sudah ditugaskan
  bool isTechnicianAssigned(int technicianId) {
    return allTechnicianIds.contains(technicianId);
  }

  /// Display untuk multiple technicians
  String get techniciansDisplay {
    final ids = allTechnicianIds;
    if (ids.isEmpty) {
      return teknisiNama ?? 'Belum ditugaskan';
    }

    if (ids.length == 1) {
      return teknisiNama ?? '1 teknisi';
    }
    return '${ids.length} teknisi';
  }

  /// Ambil nama-nama teknisi yang ditugaskan (prioritas: technicians[] -> teknisi{} -> fallback id)
  List<String> get technicianNames {
    // 1) kalau API ngirim technicians array (multi)
    if (techniciansData.isNotEmpty) {
      final names = techniciansData
          .map((t) => (t['name'] ?? '').toString().trim())
          .where((n) => n.isNotEmpty)
          .toList();
      if (names.isNotEmpty) return names;
    }

    // 2) fallback ke teknisiData (single)
    if (teknisiData != null) {
      final name = (teknisiData!['name'] ?? '').toString().trim();
      if (name.isNotEmpty) return [name];
    }

    // 3) fallback terakhir: dari id
    final ids = allTechnicianIds;
    if (ids.isNotEmpty) return ids.map((id) => 'Teknisi #$id').toList();

    return [];
  }

  /// Tampilkan nama teknisi sebagai string (contoh: "Andi, Rina")
  String get techniciansNamesDisplay {
    final names = technicianNames;
    if (names.isEmpty) return 'Belum ditugaskan';
    return names.join(', ');
  }

  /// Versi pendek untuk card (contoh: "Andi +1")
  String get techniciansShortDisplay {
    final names = technicianNames;
    if (names.isEmpty) return 'Belum ditugaskan';
    if (names.length == 1) return names.first;
    return '${names.first} +${names.length - 1}';
  }

  /// Untuk kompatibilitas dengan kode lama
  String? get primaryTechnicianName {
    if (technicianIds != null && technicianIds!.isNotEmpty) {
      return 'Tim (${technicianIds!.length} orang)';
    }
    return teknisiNama;
  }

  /// Get nama-nama semua teknisi (jika ada data teknisiData)
  // List<String> get technicianNames {
  //   final names = <String>[];
  //   for (final id in allTechnicianIds) {
  //     // Anda mungkin perlu menambahkan logic untuk mendapatkan nama dari provider
  //     names.add('Teknisi #$id');
  //   }
  //   return names;
  // }

  // ===== HELPER METHODS UNTUK DATA RELASIONAL =====

  String _getStringFromMap(Map<String, dynamic>? map, String key, [String defaultValue = '']) {
    if (map == null || map[key] == null) return defaultValue;
    return map[key].toString();
  }

  String get lokasiNama => _getStringFromMap(lokasiData, 'name', 'Tidak Diketahui');
  String get lokasiAlamat => _getStringFromMap(lokasiData, 'address', 'Tidak Diketahui');

  String get acNama => _getStringFromMap(acData, 'name', 'Tidak Diketahui');
  String get acMerk => _getStringFromMap(acData, 'brand', 'Tidak Diketahui');
  String get acType => _getStringFromMap(acData, 'type', 'Tidak Diketahui');
  String get acKapasitas => _getStringFromMap(acData, 'capacity', 'Tidak Diketahui');

  String get teknisiNama => _getStringFromMap(teknisiData, 'name', 'Teknisi Tidak Diketahui');
  String get teknisiSpesialisasi => _getStringFromMap(teknisiData, 'spesialisasi', '');
  String get teknisiPhone => _getStringFromMap(teknisiData, 'phone', '');

  double get teknisiRating {
    if (teknisiData == null || teknisiData!['rating'] == null) return 0.0;
    try {
      return double.parse(teknisiData!['rating'].toString());
    } catch (e) {
      return 0.0;
    }
  }

  int get teknisiTotalService {
    if (teknisiData == null || teknisiData!['total_service'] == null) return 0;
    try {
      return int.parse(teknisiData!['total_service'].toString());
    } catch (e) {
      return 0;
    }
  }

  String get keluhanJudul => _getStringFromMap(keluhanData, 'title', 'Tidak Diketahui');
  String get keluhanDeskripsi => _getStringFromMap(keluhanData, 'description', '');
  String get keluhanStatus => _getStringFromMap(keluhanData, 'status', '');
  String get keluhanPrioritas => _getStringFromMap(keluhanData, 'priority', '');

  DateTime? get keluhanSubmittedAt {
    if (keluhanData == null || keluhanData!['submitted_at'] == null) return null;
    try {
      return DateTime.parse(keluhanData!['submitted_at'].toString());
    } catch (e) {
      return null;
    }
  }

  // ===== COPY WITH METHOD =====

  ServisModel copyWith({
    String? id,
    String? keluhanId,
    String? lokasiId,
    String? acId,
    String? teknisiId,
    List<int>? technicianIds,
    String? technicianIdsJson,
    int? jumlahAc,
    JenisPenanganan? jenis,
    ServisStatus? status,
    List<TindakanServis>? tindakan,
    String? diagnosa,
    String? catatan,
    List<String>? fotoSebelum,
    List<String>? fotoPengerjaan,
    List<String>? fotoSesudah,
    List<String>? fotoSukuCadang,
    DateTime? tanggalBerkunjung,
    DateTime? tanggalDitugaskan,
    DateTime? tanggalMulai,
    DateTime? tanggalSelesai,
    DateTime? tanggalDikonfirmasi,
    double? biayaServis,
    double? biayaSukuCadang,
    String? noInvoice,
    Map<String, dynamic>? lokasiData,
    Map<String, dynamic>? acData,
    Map<String, dynamic>? teknisiData,
    Map<String, dynamic>? keluhanData,
  }) {
    return ServisModel(
      id: id ?? this.id,
      keluhanId: keluhanId ?? this.keluhanId,
      lokasiId: lokasiId ?? this.lokasiId,
      acId: acId ?? this.acId,
      teknisiId: teknisiId ?? this.teknisiId,
      technicianIds: technicianIds ?? this.technicianIds,
      technicianIdsJson: technicianIdsJson ?? this.technicianIdsJson,
      jumlahAc: jumlahAc ?? this.jumlahAc,
      jenis: jenis ?? this.jenis,
      status: status ?? this.status,
      tindakan: tindakan ?? this.tindakan,
      diagnosa: diagnosa ?? this.diagnosa,
      catatan: catatan ?? this.catatan,
      fotoSebelum: fotoSebelum ?? this.fotoSebelum,
      fotoPengerjaan: fotoPengerjaan ?? this.fotoPengerjaan,
      fotoSesudah: fotoSesudah ?? this.fotoSesudah,
      fotoSukuCadang: fotoSukuCadang ?? this.fotoSukuCadang,
      tanggalBerkunjung: tanggalBerkunjung ?? this.tanggalBerkunjung,
      tanggalDitugaskan: tanggalDitugaskan ?? this.tanggalDitugaskan,
      tanggalMulai: tanggalMulai ?? this.tanggalMulai,
      tanggalSelesai: tanggalSelesai ?? this.tanggalSelesai,
      tanggalDikonfirmasi: tanggalDikonfirmasi ?? this.tanggalDikonfirmasi,
      biayaServis: biayaServis ?? this.biayaServis,
      biayaSukuCadang: biayaSukuCadang ?? this.biayaSukuCadang,
      noInvoice: noInvoice ?? this.noInvoice,
      lokasiData: lokasiData ?? this.lokasiData,
      acData: acData ?? this.acData,
      teknisiData: teknisiData ?? this.teknisiData,
      keluhanData: keluhanData ?? this.keluhanData,
    );
  }

  // ===== SERIALIZATION METHODS =====

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'complaint_id': keluhanId,
      'location_id': lokasiId,
      'ac_unit_id': acId,
      'technician_id': teknisiId,
      'technician_ids': technicianIds, // PENAMBAHAN BARU
      'jumlah_ac': jumlahAc,
      'jenis': _convertJenisToApi(jenis),
      'status': _convertStatusToApi(status),
      'tindakan': tindakan.map((e) => _convertTindakanToApi(e)).toList(),
      'diagnosa': diagnosa,
      'catatan': catatan,
      'foto_sebelum': fotoSebelum,
      'foto_pengerjaan': fotoPengerjaan,
      'foto_sesudah': fotoSesudah,
      'foto_suku_cadang': fotoSukuCadang,
      'tanggal_berkunjung': tanggalBerkunjung?.toIso8601String(),
      'tanggal_ditugaskan': tanggalDitugaskan.toIso8601String(),
      'tanggal_mulai': tanggalMulai?.toIso8601String(),
      'tanggal_selesai': tanggalSelesai?.toIso8601String(),
      'tanggal_dikonfirmasi': tanggalDikonfirmasi?.toIso8601String(),
      'biaya_servis': biayaServis,
      'biaya_suku_cadang': biayaSukuCadang,
      'no_invoice': noInvoice,
      if (lokasiData != null) 'lokasi': lokasiData,
      if (acData != null) 'ac': acData,
      if (teknisiData != null) 'teknisi': teknisiData,
      if (keluhanData != null) 'keluhan': keluhanData,
    };
  }

  factory ServisModel.fromMap(Map<String, dynamic> map) {
    // Parse data dasar
    final String id = (map['id'] ?? '').toString();
    final String keluhanId = (map['complaint_id'] ?? map['keluhan_id'] ?? '').toString();
    final String lokasiId = (map['location_id'] ?? map['lokasi_id'] ?? '').toString();
    final String acId = (map['ac_unit_id'] ?? map['ac_id'] ?? '').toString();
    final String teknisiId = (map['technician_id'] ?? map['teknisi_id'] ?? '').toString();
    final int jumlahAC = (map['jumlah_ac'] ?? 0);

    // ===== PARSE MULTIPLE TECHNICIANS - PENAMBAHAN BARU =====
    List<int>? parsedTechnicianIds;
    String? technicianIdsJson;

    // ✅ Parse technicians array dari API
    List<Map<String, dynamic>> parsedTechniciansData = [];
    if (map['technicians'] is List) {
      parsedTechniciansData = (map['technicians'] as List)
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

// Kalau technicians ada, kita bisa ambil ids langsung dari situ (lebih valid)
    if (parsedTechniciansData.isNotEmpty) {
      final idsFromTechnicians = parsedTechniciansData
          .map((t) => int.tryParse((t['id'] ?? '').toString()) ?? 0)
          .where((id) => id > 0)
          .toList();
      if (idsFromTechnicians.isNotEmpty) {
        parsedTechnicianIds = idsFromTechnicians;
      }
    }


    // Coba parse technician_ids dari berbagai format
    if (map['technician_ids'] != null) {
      technicianIdsJson = map['technician_ids']?.toString();

      if (map['technician_ids'] is List) {
        try {
          parsedTechnicianIds = (map['technician_ids'] as List)
              .where((id) => id != null)
              .map((id) => int.tryParse(id.toString()) ?? 0)
              .where((id) => id > 0)
              .toList();
        } catch (e) {
          print('❌ Error parsing technician_ids as List: $e');
        }
      } else if (map['technician_ids'] is String) {
        final jsonString = map['technician_ids'] as String;
        technicianIdsJson = jsonString;

        try {
          if (jsonString.startsWith('[')) {
            final parsed = jsonDecode(jsonString) as List;
            parsedTechnicianIds = parsed
                .where((id) => id != null)
                .map((id) => int.tryParse(id.toString()) ?? 0)
                .where((id) => id > 0)
                .toList();
          } else {
            // Mungkin single ID sebagai string
            final id = int.tryParse(jsonString);
            if (id != null && id > 0) {
              parsedTechnicianIds = [id];
            }
          }
        } catch (e) {
          print('❌ Error parsing technician_ids as JSON string: $e');
        }
      }
    }

    // Jika technician_ids kosong, coba dari teknisiId (single)
    if ((parsedTechnicianIds == null || parsedTechnicianIds.isEmpty) && teknisiId.isNotEmpty) {
      final id = int.tryParse(teknisiId);
      if (id != null && id > 0) {
        parsedTechnicianIds = [id];
      }
    }

    // Parse enums dari API
    final String statusApi = (map['status'] ?? 'menunggu_konfirmasi').toString();
    final ServisStatus status = _parseStatusFromApi(statusApi);

    final String jenisApi = (map['jenis'] ?? 'perbaikan').toString();
    final JenisPenanganan jenis = _parseJenisFromApi(jenisApi);

    final List<TindakanServis> tindakanList = _parseTindakanFromApi(
        map['tindakan'] as List<dynamic>? ?? []);

    // Parse foto dengan lebih aman
    List<String> parseFotoList(dynamic fotoData) {
      if (fotoData == null) return [];
      if (fotoData is List) {
        try {
          return fotoData.map((e) => e.toString()).toList();
        } catch (e) {
          return [];
        }
      }
      return [];
    }

    return ServisModel(
      id: id,
      keluhanId: keluhanId,
      lokasiId: lokasiId,
      acId: acId,
      teknisiId: teknisiId,

      // PENAMBAHAN BARU
      technicianIds: parsedTechnicianIds,
      technicianIdsJson: technicianIdsJson,

      jumlahAc: jumlahAC > 0 ? jumlahAC : null,
      jenis: jenis,
      status: status,
      tindakan: tindakanList,
      diagnosa: (map['diagnosa'] ?? '').toString(),
      catatan: (map['catatan'] ?? '').toString(),
      fotoSebelum: parseFotoList(map['foto_sebelum']),
      fotoPengerjaan: parseFotoList(map['foto_pengerjaan']),
      fotoSesudah: parseFotoList(map['foto_sesudah']),
      fotoSukuCadang: parseFotoList(map['foto_suku_cadang']),
      tanggalBerkunjung: _parseNullableDateTime(map['tanggal_berkunjung']),
      tanggalDitugaskan: _parseDateTime(map['tanggal_ditugaskan']),
      tanggalMulai: _parseNullableDateTime(map['tanggal_mulai']),
      tanggalSelesai: _parseNullableDateTime(map['tanggal_selesai']),
      tanggalDikonfirmasi: _parseNullableDateTime(map['tanggal_dikonfirmasi']),
      biayaServis: _parseDouble(map['biaya_servis']),
      biayaSukuCadang: _parseDouble(map['biaya_suku_cadang']),
      noInvoice: map['no_invoice'] as String?,

      lokasiData: _convertToMap(map['lokasi']),
      acData: _convertToMap(map['ac']),
      teknisiData: _convertToMap(map['teknisi']),
      keluhanData: _convertToMap(map['keluhan']),

      techniciansData: parsedTechniciansData,
    );
  }


  // ===== HELPER STATIC METHODS =====
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    try {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  static Map<String, dynamic>? _convertToMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  factory ServisModel.fromJson(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return ServisModel.fromMap(map);
  }

  String toJson() => jsonEncode(toMap());

  // Parse DateTime dengan error handling
  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    try {
      return DateTime.parse(dateValue.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  static DateTime? _parseNullableDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    try {
      return DateTime.parse(dateValue.toString());
    } catch (e) {
      return null;
    }
  }

  // ===== ENUM PARSING =====

  static ServisStatus _parseStatusFromApi(String status) {
    final Map<String, ServisStatus> statusMap = {
      'menunggu_konfirmasi': ServisStatus.menunggu_konfirmasi,
      'ditugaskan': ServisStatus.ditugaskan,
      'dikerjakan': ServisStatus.dikerjakan,
      'selesai': ServisStatus.selesai,
      'batal': ServisStatus.batal,
      'dalam_perjalanan': ServisStatus.dalam_perjalanan,
      'tiba_di_lokasi': ServisStatus.tiba_di_lokasi,
      'sedang_diperiksa': ServisStatus.sedang_diperiksa,
      'dalam_perbaikan': ServisStatus.dalam_perbaikan,
      'menunggu_suku_cadang': ServisStatus.menunggu_suku_cadang,
      'ditolak': ServisStatus.ditolak,
      'menunggu_konfirmasi_owner': ServisStatus.menunggu_konfirmasi_owner,
    };
    return statusMap[status.toLowerCase()] ?? ServisStatus.menunggu_konfirmasi;
  }

  static JenisPenanganan _parseJenisFromApi(String jenis) {
    final Map<String, JenisPenanganan> jenisMap = {
      'cuci': JenisPenanganan.cuciAc,
      'perbaikan': JenisPenanganan.perbaikanAc,
      'instalasi': JenisPenanganan.instalasi,
    };
    return jenisMap[jenis.toLowerCase()] ?? JenisPenanganan.perbaikanAc;
  }

  static List<TindakanServis> _parseTindakanFromApi(List<dynamic> tindakanList) {
    final Map<String, TindakanServis> tindakanMap = {
      'pembersihan': TindakanServis.pembersihan,
      'isi_freon': TindakanServis.isiFreon,
      'ganti_filter': TindakanServis.gantiFilter,
      'perbaikan_kompressor': TindakanServis.perbaikanKompressor,
      'perbaikan_pcb': TindakanServis.perbaikanPCB,
      'ganti_kapasitor': TindakanServis.gantiKapasitor,
      'ganti_fan_motor': TindakanServis.gantiFanMotor,
      'tune_up': TindakanServis.tuneUp,
      'lainnya': TindakanServis.lainnya,
    };

    return tindakanList
        .map((e) => tindakanMap[e.toString()] ?? TindakanServis.lainnya)
        .toList();
  }

  static String _convertStatusToApi(ServisStatus status) {
    switch (status) {
      case ServisStatus.menunggu_konfirmasi: return 'menunggu_konfirmasi';
      case ServisStatus.ditugaskan: return 'ditugaskan';
      case ServisStatus.dikerjakan: return 'dikerjakan';
      case ServisStatus.selesai: return 'selesai';
      case ServisStatus.batal: return 'batal';
      case ServisStatus.dalam_perjalanan: return 'dalam_perjalanan';
      case ServisStatus.tiba_di_lokasi: return 'tiba_di_lokasi';
      case ServisStatus.sedang_diperiksa: return 'sedang_diperiksa';
      case ServisStatus.dalam_perbaikan: return 'dalam_perbaikan';
      case ServisStatus.menunggu_suku_cadang: return 'menunggu_suku_cadang';
      case ServisStatus.ditolak: return 'ditolak';
      case ServisStatus.menunggu_konfirmasi_owner: return 'menunggu_konfirmasi_owner';
    }
  }

  static String _convertJenisToApi(JenisPenanganan jenis) {
    switch (jenis) {
      case JenisPenanganan.cuciAc: return 'cuci';
      case JenisPenanganan.perbaikanAc: return 'perbaikan';
      case JenisPenanganan.instalasi: return 'instalasi';
    }
  }

  static String _convertTindakanToApi(TindakanServis tindakan) {
    switch (tindakan) {
      case TindakanServis.pembersihan: return 'pembersihan';
      case TindakanServis.isiFreon: return 'isi_freon';
      case TindakanServis.gantiFilter: return 'ganti_filter';
      case TindakanServis.perbaikanKompressor: return 'perbaikan_kompressor';
      case TindakanServis.perbaikanPCB: return 'perbaikan_pcb';
      case TindakanServis.gantiKapasitor: return 'ganti_kapasitor';
      case TindakanServis.gantiFanMotor: return 'ganti_fan_motor';
      case TindakanServis.tuneUp: return 'tune_up';
      case TindakanServis.lainnya: return 'lainnya';
    }
  }

  // ===== DISPLAY PROPERTIES =====

  String get statusDisplay {
    switch (status) {
      case ServisStatus.menunggu_konfirmasi: return 'Menunggu Konfirmasi';
      case ServisStatus.ditugaskan: return 'Ditugaskan';
      case ServisStatus.dikerjakan: return 'Dikerjakan';
      case ServisStatus.selesai: return 'Selesai';
      case ServisStatus.batal: return 'Dibatalkan';
      case ServisStatus.dalam_perjalanan: return 'Dalam Perjalanan';
      case ServisStatus.tiba_di_lokasi: return 'Tiba di Lokasi';
      case ServisStatus.sedang_diperiksa: return 'Sedang Diperiksa';
      case ServisStatus.dalam_perbaikan: return 'Dalam Perbaikan';
      case ServisStatus.menunggu_suku_cadang: return 'Menunggu Suku Cadang';
      case ServisStatus.ditolak: return 'Ditolak';
      case ServisStatus.menunggu_konfirmasi_owner: return 'Menunggu Konfirmasi Owner';
    }
  }

  Color get statusColor {
    switch (status) {
      case ServisStatus.menunggu_konfirmasi: return Colors.orange;
      case ServisStatus.ditugaskan: return Colors.blue;
      case ServisStatus.dikerjakan: return Colors.purple;
      case ServisStatus.selesai: return Colors.green;
      case ServisStatus.batal: return Colors.red;
      case ServisStatus.dalam_perjalanan: return Colors.cyan;
      case ServisStatus.tiba_di_lokasi: return Colors.orange[300]!;
      case ServisStatus.sedang_diperiksa: return Colors.purple;
      case ServisStatus.dalam_perbaikan: return Colors.purple[300]!;
      case ServisStatus.menunggu_suku_cadang: return Colors.yellow[700]!;
      case ServisStatus.ditolak: return Colors.red;
      case ServisStatus.menunggu_konfirmasi_owner: return Colors.amber;
    }
  }

  String get jenisDisplay {
    switch (jenis) {
      case JenisPenanganan.cuciAc: return 'Cuci AC';
      case JenisPenanganan.perbaikanAc: return 'Perbaikan AC';
      case JenisPenanganan.instalasi: return 'Instalasi AC';
    }
  }

  Color get jenisColor {
    switch (jenis) {
      case JenisPenanganan.cuciAc: return Colors.blue;
      case JenisPenanganan.perbaikanAc: return Colors.orange;
      case JenisPenanganan.instalasi: return Colors.green;
    }
  }

  IconData get jenisIcon {
    switch (jenis) {
      case JenisPenanganan.cuciAc: return Icons.clean_hands;
      case JenisPenanganan.perbaikanAc: return Icons.build;
      case JenisPenanganan.instalasi: return Icons.install_desktop;
    }
  }

  // Getter untuk format tanggal berkunjung
  String get tanggalBerkunjungDisplay {
    if (tanggalBerkunjung == null) return 'Belum ditentukan';
    return _formatDateTime(tanggalBerkunjung!);
  }

  String get tanggalBerkunjungShort {
    if (tanggalBerkunjung == null) return '-';
    return '${tanggalBerkunjung!.day}/${tanggalBerkunjung!.month}/${tanggalBerkunjung!.year}';
  }

  String get waktuBerkunjung {
    if (tanggalBerkunjung == null) return '-';
    return '${tanggalBerkunjung!.hour.toString().padLeft(2, '0')}:${tanggalBerkunjung!.minute.toString().padLeft(2, '0')}';
  }

  // Format currency helper
  String get formattedTotalBiaya {
    return _formatCurrency(totalBiaya);
  }

  String get formattedBiayaServis {
    return _formatCurrency(biayaServis);
  }

  String get formattedBiayaSukuCadang {
    return _formatCurrency(biayaSukuCadang);
  }

  static String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    )}';
  }

  static String _formatDateTime(DateTime date) {
    final dayNames = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    return '${dayNames[date.weekday % 7]}, ${date.day} ${monthNames[date.month - 1]} ${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // ===== BUSINESS LOGIC HELPERS =====

  bool get isCompleted => status == ServisStatus.selesai;
  bool get isInProgress => status == ServisStatus.ditugaskan || status == ServisStatus.dikerjakan;
  bool get requiresConfirmation => status == ServisStatus.menunggu_konfirmasi;
  bool get isRejected => status == ServisStatus.ditolak;
  bool get isCancelled => status == ServisStatus.batal;

  bool get isTanggalBerkunjungTerlewat {
    if (tanggalBerkunjung == null) return false;
    return tanggalBerkunjung!.isBefore(DateTime.now());
  }

  bool get isTanggalBerkunjungMendekat {
    if (tanggalBerkunjung == null) return false;
    final now = DateTime.now();
    final difference = tanggalBerkunjung!.difference(now);
    return difference.inDays <= 2 && difference.inDays >= 0;
  }

  Duration? get duration {
    if (tanggalMulai == null || tanggalSelesai == null) return null;
    return tanggalSelesai!.difference(tanggalMulai!);
  }

  String? get durationDisplay {
    final dur = duration;
    if (dur == null) return null;

    if (dur.inHours < 1) {
      return '${dur.inMinutes} menit';
    } else if (dur.inHours < 24) {
      return '${dur.inHours} jam';
    } else {
      return '${dur.inDays} hari';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ServisModel &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}
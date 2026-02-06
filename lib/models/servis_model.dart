// lib/models/servis_model.dart
import 'dart:convert';
import 'package:flutter/material.dart';

enum ServisStatus {
  ditugaskan,
  dalamPerjalanan,
  tibaDiLokasi,
  sedangDiperiksa,
  dalamPerbaikan,
  menungguSukuCadang,
  selesai,
  ditolak,
  menungguKonfirmasi,
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
  final String teknisiId;
  final JenisPenanganan jenis;

  final ServisStatus status;
  final List<TindakanServis> tindakan;

  final String diagnosa;
  final String catatan;

  final List<String> fotoSebelum;
  final List<String> fotoPengerjaan;
  final List<String> fotoSesudah;
  final List<String> fotoSukuCadang;

  // TANGGAL BARU DITAMBAHKAN
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

  const ServisModel({
    required this.id,
    required this.keluhanId,
    required this.lokasiId,
    required this.acId,
    required this.teknisiId,
    this.jenis = JenisPenanganan.perbaikanAc,
    this.status = ServisStatus.ditugaskan,
    this.tindakan = const [],
    this.diagnosa = '',
    this.catatan = '',
    this.fotoSebelum = const [],
    this.fotoPengerjaan = const [],
    this.fotoSesudah = const [],
    this.fotoSukuCadang = const [],
    this.tanggalBerkunjung, // TAMBAHKAN DI CONSTRUCTOR
    required this.tanggalDitugaskan,
    this.tanggalMulai,
    this.tanggalSelesai,
    this.tanggalDikonfirmasi,
    this.biayaServis = 0,
    this.biayaSukuCadang = 0,
    this.noInvoice,
    // Data relasional
    this.lokasiData,
    this.acData,
    this.teknisiData,
    this.keluhanData,
  });

  double get totalBiaya => biayaServis + biayaSukuCadang;

  // Helper method untuk mendapatkan string dari map dengan null safety
  String _getStringFromMap(Map<String, dynamic>? map, String key, [String defaultValue = '']) {
    if (map == null || map[key] == null) return defaultValue;
    return map[key].toString();
  }

  // Getter untuk data relasional dengan null safety yang sudah diperbaiki
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

  ServisModel copyWith({
    String? id,
    String? keluhanId,
    String? lokasiId,
    String? acId,
    String? teknisiId,
    JenisPenanganan? jenis,
    ServisStatus? status,
    List<TindakanServis>? tindakan,
    String? diagnosa,
    String? catatan,
    List<String>? fotoSebelum,
    List<String>? fotoPengerjaan,
    List<String>? fotoSesudah,
    List<String>? fotoSukuCadang,
    DateTime? tanggalBerkunjung, // TAMBAHKAN DI COPYWITH
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
      jenis: jenis ?? this.jenis,
      status: status ?? this.status,
      tindakan: tindakan ?? this.tindakan,
      diagnosa: diagnosa ?? this.diagnosa,
      catatan: catatan ?? this.catatan,
      fotoSebelum: fotoSebelum ?? this.fotoSebelum,
      fotoPengerjaan: fotoPengerjaan ?? this.fotoPengerjaan,
      fotoSesudah: fotoSesudah ?? this.fotoSesudah,
      fotoSukuCadang: fotoSukuCadang ?? this.fotoSukuCadang,
      tanggalBerkunjung: tanggalBerkunjung ?? this.tanggalBerkunjung, // TAMBAHKAN
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

  /// Konversi ke Map untuk API (snake_case)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'complaint_id': keluhanId,
      'location_id': lokasiId,
      'ac_unit_id': acId,
      'technician_id': teknisiId,
      'jenis': _convertJenisToApi(jenis),
      'status': _convertStatusToApi(status),
      'tindakan': tindakan.map((e) => _convertTindakanToApi(e)).toList(),
      'diagnosa': diagnosa,
      'catatan': catatan,
      'foto_sebelum': fotoSebelum,
      'foto_pengerjaan': fotoPengerjaan,
      'foto_sesudah': fotoSesudah,
      'foto_suku_cadang': fotoSukuCadang,
      'tanggal_berkunjung': tanggalBerkunjung?.toIso8601String(), // TAMBAHKAN
      'tanggal_ditugaskan': tanggalDitugaskan.toIso8601String(),
      'tanggal_mulai': tanggalMulai?.toIso8601String(),
      'tanggal_selesai': tanggalSelesai?.toIso8601String(),
      'tanggal_dikonfirmasi': tanggalDikonfirmasi?.toIso8601String(),
      'biaya_servis': biayaServis,
      'biaya_suku_cadang': biayaSukuCadang,
      'no_invoice': noInvoice,
      // Data relasional (opsional untuk disimpan)
      if (lokasiData != null) 'lokasi': lokasiData,
      if (acData != null) 'ac': acData,
      if (teknisiData != null) 'teknisi': teknisiData,
      if (keluhanData != null) 'keluhan': keluhanData,
    };
  }

  /// Konversi dari API response (snake_case) ke ServisModel
  factory ServisModel.fromMap(Map<String, dynamic> map) {
    // Debug untuk melihat struktur data
    print('=== DEBUG SERVIS MODEL ===');
    print('Full map keys: ${map.keys.toList()}');

    // Parse data yang diperlukan
    final String id = (map['id'] ?? '').toString();
    final String keluhanId = (map['complaint_id'] ?? map['keluhan_id'] ?? '').toString();
    final String lokasiId = (map['location_id'] ?? map['lokasi_id'] ?? '').toString();
    final String acId = (map['ac_unit_id'] ?? map['ac_id'] ?? '').toString();
    final String teknisiId = (map['technician_id'] ?? map['teknisi_id'] ?? '').toString();

    // Parse enums dari API (snake_case) ke Dart enum
    final String statusApi = (map['status'] ?? 'ditugaskan').toString();
    final ServisStatus status = _parseStatusFromApi(statusApi);

    final String jenisApi = (map['jenis'] ?? 'perbaikan').toString();
    final JenisPenanganan jenis = _parseJenisFromApi(jenisApi);

    final List<TindakanServis> tindakanList = _parseTindakanFromApi(
        map['tindakan'] as List<dynamic>? ?? []);

    // Debug foto untuk verifikasi
    print('foto_sebelum: ${map['foto_sebelum']}');
    print('foto_pengerjaan: ${map['foto_pengerjaan']}');
    print('foto_sesudah: ${map['foto_sesudah']}');
    print('foto_suku_cadang: ${map['foto_suku_cadang']}');

    // Parse foto dengan lebih aman
    List<String> parseFotoList(dynamic fotoData) {
      if (fotoData == null) return [];
      if (fotoData is List) {
        try {
          return fotoData.map((e) => e.toString()).toList();
        } catch (e) {
          print('Error parsing foto list: $e');
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
      jenis: jenis,
      status: status,
      tindakan: tindakanList,
      diagnosa: (map['diagnosa'] ?? '').toString(),
      catatan: (map['catatan'] ?? '').toString(),
      fotoSebelum: parseFotoList(map['foto_sebelum']),
      fotoPengerjaan: parseFotoList(map['foto_pengerjaan']),
      fotoSesudah: parseFotoList(map['foto_sesudah']),
      fotoSukuCadang: parseFotoList(map['foto_suku_cadang']),
      tanggalBerkunjung: _parseNullableDateTime(map['tanggal_berkunjung']), // TAMBAHKAN PARSING
      tanggalDitugaskan: _parseDateTime(map['tanggal_ditugaskan']),
      tanggalMulai: _parseNullableDateTime(map['tanggal_mulai']),
      tanggalSelesai: _parseNullableDateTime(map['tanggal_selesai']),
      tanggalDikonfirmasi: _parseNullableDateTime(map['tanggal_dikonfirmasi']),
      biayaServis: _parseDouble(map['biaya_servis']),
      biayaSukuCadang: _parseDouble(map['biaya_suku_cadang']),
      noInvoice: map['no_invoice'] as String?,
      // Data relasional - pastikan tipe Map<String, dynamic>
      lokasiData: _convertToMap(map['lokasi']),
      acData: _convertToMap(map['ac']),
      teknisiData: _convertToMap(map['teknisi']),
      keluhanData: _convertToMap(map['keluhan']),
    );
  }

  /// Parse double dengan error handling
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    try {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    } catch (e) {
      print('Error parsing double: $value, error: $e');
      return 0.0;
    }
  }

  /// Helper untuk mengonversi ke Map<String, dynamic>
  static Map<String, dynamic>? _convertToMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  /// Konversi dari JSON string
  factory ServisModel.fromJson(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return ServisModel.fromMap(map);
  }

  /// Konversi ke JSON string
  String toJson() => jsonEncode(toMap());

  // === HELPER METHODS ===

  // Parse DateTime dengan error handling
  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    try {
      return DateTime.parse(dateValue.toString());
    } catch (e) {
      print('Error parsing date: $dateValue, error: $e');
      return DateTime.now();
    }
  }

  static DateTime? _parseNullableDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    try {
      return DateTime.parse(dateValue.toString());
    } catch (e) {
      print('Error parsing nullable date: $dateValue, error: $e');
      return null;
    }
  }

  // Parse status dari API (snake_case) ke enum
  static ServisStatus _parseStatusFromApi(String status) {
    final Map<String, ServisStatus> statusMap = {
      'ditugaskan': ServisStatus.ditugaskan,
      'dalam_perjalanan': ServisStatus.dalamPerjalanan,
      'tiba_di_lokasi': ServisStatus.tibaDiLokasi,
      'sedang_diperiksa': ServisStatus.sedangDiperiksa,
      'dalam_perbaikan': ServisStatus.dalamPerbaikan,
      'menunggu_suku_cadang': ServisStatus.menungguSukuCadang,
      'selesai': ServisStatus.selesai,
      'ditolak': ServisStatus.ditolak,
      'menunggu_konfirmasi': ServisStatus.menungguKonfirmasi,
    };
    return statusMap[status] ?? ServisStatus.ditugaskan;
  }

  // Parse jenis dari API ke enum
  static JenisPenanganan _parseJenisFromApi(String jenis) {
    final Map<String, JenisPenanganan> jenisMap = {
      'cuci': JenisPenanganan.cuciAc,
      'perbaikan': JenisPenanganan.perbaikanAc,
      'instalasi': JenisPenanganan.instalasi,
      'cuci_ac': JenisPenanganan.cuciAc,
      'perbaikan_ac': JenisPenanganan.perbaikanAc,
    };
    return jenisMap[jenis] ?? JenisPenanganan.perbaikanAc;
  }

  // Parse tindakan dari API (snake_case) ke enum
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

  // Convert enum ke format API (snake_case)
  static String _convertStatusToApi(ServisStatus status) {
    switch (status) {
      case ServisStatus.ditugaskan: return 'ditugaskan';
      case ServisStatus.dalamPerjalanan: return 'dalam_perjalanan';
      case ServisStatus.tibaDiLokasi: return 'tiba_di_lokasi';
      case ServisStatus.sedangDiperiksa: return 'sedang_diperiksa';
      case ServisStatus.dalamPerbaikan: return 'dalam_perbaikan';
      case ServisStatus.menungguSukuCadang: return 'menunggu_suku_cadang';
      case ServisStatus.selesai: return 'selesai';
      case ServisStatus.ditolak: return 'ditolak';
      case ServisStatus.menungguKonfirmasi: return 'menunggu_konfirmasi';
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

  // === DISPLAY PROPERTIES ===

  String get statusDisplay {
    switch (status) {
      case ServisStatus.ditugaskan: return 'Ditugaskan';
      case ServisStatus.dalamPerjalanan: return 'Dalam Perjalanan';
      case ServisStatus.tibaDiLokasi: return 'Tiba di Lokasi';
      case ServisStatus.sedangDiperiksa: return 'Sedang Diperiksa';
      case ServisStatus.dalamPerbaikan: return 'Dalam Perbaikan';
      case ServisStatus.menungguSukuCadang: return 'Menunggu Suku Cadang';
      case ServisStatus.selesai: return 'Selesai';
      case ServisStatus.ditolak: return 'Ditolak';
      case ServisStatus.menungguKonfirmasi: return 'Menunggu Konfirmasi';
    }
  }

  Color get statusColor {
    switch (status) {
      case ServisStatus.ditugaskan: return Colors.blue;
      case ServisStatus.dalamPerjalanan: return Colors.orange;
      case ServisStatus.tibaDiLokasi: return Colors.orange[300]!;
      case ServisStatus.sedangDiperiksa: return Colors.purple;
      case ServisStatus.dalamPerbaikan: return Colors.purple[300]!;
      case ServisStatus.menungguSukuCadang: return Colors.yellow[700]!;
      case ServisStatus.selesai: return Colors.green;
      case ServisStatus.ditolak: return Colors.red;
      case ServisStatus.menungguKonfirmasi: return Colors.yellow[700]!;
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

  // Business logic helpers
  bool get isCompleted => status == ServisStatus.selesai;
  bool get isInProgress => [
    ServisStatus.ditugaskan,
    ServisStatus.dalamPerjalanan,
    ServisStatus.tibaDiLokasi,
    ServisStatus.sedangDiperiksa,
    ServisStatus.dalamPerbaikan,
    ServisStatus.menungguSukuCadang,
  ].contains(status);

  bool get requiresConfirmation => status == ServisStatus.menungguKonfirmasi;
  bool get isRejected => status == ServisStatus.ditolak;

  // Helper untuk mengecek apakah tanggal berkunjung sudah lewat
  bool get isTanggalBerkunjungTerlewat {
    if (tanggalBerkunjung == null) return false;
    return tanggalBerkunjung!.isBefore(DateTime.now());
  }

  // Helper untuk mengecek apakah tanggal berkunjung sudah dekat (dalam 2 hari)
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

  // Debug method untuk mengecek data
  void debugData() {
    print('=== DEBUG SERVIS MODEL DATA ===');
    print('ID: $id');
    print('Status: $statusDisplay');
    print('Tanggal Berkunjung: $tanggalBerkunjung');
    print('Tanggal Berkunjung Display: $tanggalBerkunjungDisplay');
    print('Lokasi Data exists: ${lokasiData != null}');
    print('Lokasi Data: $lokasiData');
    print('Lokasi Name from data: ${lokasiData?['name']}');
    print('Lokasi Name from getter: $lokasiNama');
    print('AC Data: $acData');
    print('AC Name from getter: $acNama');
    print('Teknisi Data: $teknisiData');
    print('Teknisi Name from getter: $teknisiNama');
    print('===============================');
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
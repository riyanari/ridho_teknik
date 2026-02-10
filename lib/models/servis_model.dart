import 'dart:convert';
import 'package:flutter/material.dart';

enum ServisStatus {
  menunggu_konfirmasi,
  ditugaskan,
  dikerjakan,
  selesai,
  batal,

  // Legacy (kompatibilitas)
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

  /// SINGLE TECHNICIAN (backward compat)
  final String teknisiId;

  /// MULTI technician IDs (optional)
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

  /// di API kadang null → kita fallback ke now biar UI aman
  final DateTime tanggalDitugaskan;
  final DateTime? tanggalMulai;
  final DateTime? tanggalSelesai;
  final DateTime? tanggalDikonfirmasi;

  final double biayaServis;
  final double biayaSukuCadang;
  final String? noInvoice;

  // Relasi dari API
  final Map<String, dynamic>? lokasiData;
  final Map<String, dynamic>? acData; // untuk perbaikan single
  final Map<String, dynamic>? teknisiData; // single (legacy)
  final Map<String, dynamic>? keluhanData;

  /// Multi technicians detail dari API
  final List<Map<String, dynamic>> techniciansData;

  /// ac_units_detail dari API (kalau ada)
  final List<Map<String, dynamic>> acUnitsDetail;

  /// service items dari API (service_items)
  /// contoh: items: [{..., ac_unit: {...}, technician: {...}}]
  final List<Map<String, dynamic>> itemsData;

  const ServisModel({
    required this.id,
    required this.keluhanId,
    required this.lokasiId,
    required this.acId,
    required this.teknisiId,
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
    this.acUnitsDetail = const [],
    this.itemsData = const [],
  });

  // =====================
  // BASIC HELPERS
  // =====================
  double get totalBiaya => biayaServis + biayaSukuCadang;

  String _getStringFromMap(Map<String, dynamic>? map, String key,
      [String defaultValue = '']) {
    if (map == null || map[key] == null) return defaultValue;
    return map[key].toString();
  }

  // Lokasi
  String get lokasiNama => _getStringFromMap(lokasiData, 'name', 'Tidak Diketahui');
  String get lokasiAlamat =>
      _getStringFromMap(lokasiData, 'address', 'Tidak Diketahui');

  // AC (single perbaikan)
  String get acNama => _getStringFromMap(acData, 'name', 'Tidak Diketahui');
  String get acMerk => _getStringFromMap(acData, 'brand', 'Tidak Diketahui');
  String get acType => _getStringFromMap(acData, 'type', 'Tidak Diketahui');
  String get acKapasitas =>
      _getStringFromMap(acData, 'capacity', 'Tidak Diketahui');

  // teknisi single (legacy)
  String get teknisiNama => _getStringFromMap(teknisiData, 'name', 'Belum ditugaskan');
  String get teknisiSpesialisasi => _getStringFromMap(teknisiData, 'spesialisasi', '');
  String get teknisiPhone => _getStringFromMap(teknisiData, 'phone', '');

  // keluhan
  String get keluhanJudul =>
      _getStringFromMap(keluhanData, 'title', 'Tidak Diketahui');
  String get keluhanDeskripsi => _getStringFromMap(keluhanData, 'description', '');
  String get keluhanStatus => _getStringFromMap(keluhanData, 'status', '');
  String get keluhanPrioritas => _getStringFromMap(keluhanData, 'priority', '');

  DateTime? get keluhanSubmittedAt {
    if (keluhanData == null || keluhanData!['submitted_at'] == null) return null;
    try {
      return DateTime.parse(keluhanData!['submitted_at'].toString());
    } catch (_) {
      return null;
    }
  }

  // =====================
  // MULTI TECHNICIANS
  // =====================
  List<int> get allTechnicianIds {
    if (technicianIds != null && technicianIds!.isNotEmpty) {
      return technicianIds!;
    }

    // fallback: dari teknisiId lama
    if (teknisiId.isNotEmpty) {
      final id = int.tryParse(teknisiId);
      if (id != null) return [id];
    }

    // fallback: dari techniciansData
    if (techniciansData.isNotEmpty) {
      final ids = techniciansData
          .map((t) => int.tryParse((t['id'] ?? '').toString()))
          .where((id) => id != null)
          .map((id) => id!)
          .toList();
      if (ids.isNotEmpty) return ids;
    }

    // fallback terakhir: dari itemsData (technician_id)
    final idsFromItems = itemsData
        .map((it) => int.tryParse((it['technician_id'] ?? '').toString()))
        .where((id) => id != null && id > 0)
        .map((id) => id!)
        .toSet()
        .toList();
    return idsFromItems;
  }

  /// Ambil nama teknisi:
  /// prioritas: techniciansData -> itemsData.technician -> teknisiData -> fallback id
  List<String> get technicianNames {
    // 1) dari technicians array
    if (techniciansData.isNotEmpty) {
      final names = techniciansData
          .map((t) => (t['name'] ?? '').toString().trim())
          .where((n) => n.isNotEmpty)
          .toList();
      if (names.isNotEmpty) return names;
    }

    // 2) dari items[].technician
    final namesFromItems = itemsData
        .map((it) => it['technician'])
        .where((t) => t is Map)
        .map((t) => (t as Map)['name']?.toString().trim() ?? '')
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();
    if (namesFromItems.isNotEmpty) return namesFromItems;

    // 3) single legacy
    if (teknisiData != null) {
      final name = (teknisiData!['name'] ?? '').toString().trim();
      if (name.isNotEmpty) return [name];
    }

    // 4) fallback id
    final ids = allTechnicianIds;
    if (ids.isNotEmpty) return ids.map((id) => 'Teknisi #$id').toList();

    return [];
  }

  String get techniciansNamesDisplay {
    final names = technicianNames;
    if (names.isEmpty) return 'Belum ditugaskan';
    return names.join(', ');
  }

  String get techniciansShortDisplay {
    final names = technicianNames;
    if (names.isEmpty) return 'Belum ditugaskan';
    if (names.length == 1) return names.first;
    return '${names.first} +${names.length - 1}';
  }

  // =====================
  // AC MULTI (SERVICE ITEMS)
  // =====================

  /// Nama AC dari acUnitsDetail, kalau kosong ambil dari itemsData[].ac_unit
  List<String> get acUnitsNames {
    // 1) ac_units_detail
    if (acUnitsDetail.isNotEmpty) {
      final names = acUnitsDetail
          .map((e) => (e['name'] ?? '').toString().trim())
          .where((n) => n.isNotEmpty)
          .toList();
      if (names.isNotEmpty) return names;
    }

    // 2) items[].ac_unit
    final namesFromItems = itemsData
        .map((it) => it['ac_unit'])
        .where((u) => u is Map)
        .map((u) => (u as Map)['name']?.toString().trim() ?? '')
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();

    return namesFromItems;
  }

  String get acUnitsNamesDisplay {
    final names = acUnitsNames;
    if (names.isEmpty) return '-';
    return names.join(', ');
  }

  /// Display AC paling masuk akal:
  /// - perbaikan: single acData
  /// - cuci: acUnitsNames (dari items)
  /// - instalasi: "Instalasi X unit"
  String get acDisplay {
    if (jenis == JenisPenanganan.instalasi) {
      final j = jumlahAc ?? 0;
      if (j > 0) return 'Instalasi $j unit';
      return 'Instalasi';
    }

    // perbaikan single
    if (acData != null && acData!.isNotEmpty) return acNama;

    // multi
    final names = acUnitsNames;
    if (names.isNotEmpty) {
      if (names.length <= 2) return names.join(', ');
      return '${names.first} +${names.length - 1}';
    }

    return 'Tidak Diketahui';
  }

  // =====================
  // DISPLAY / UI
  // =====================
  String get statusDisplay {
    switch (status) {
      case ServisStatus.menunggu_konfirmasi:
        return 'Menunggu Konfirmasi';
      case ServisStatus.ditugaskan:
        return 'Ditugaskan';
      case ServisStatus.dikerjakan:
        return 'Dikerjakan';
      case ServisStatus.selesai:
        return 'Selesai';
      case ServisStatus.batal:
        return 'Dibatalkan';

    // legacy
      case ServisStatus.dalam_perjalanan:
        return 'Dalam Perjalanan';
      case ServisStatus.tiba_di_lokasi:
        return 'Tiba di Lokasi';
      case ServisStatus.sedang_diperiksa:
        return 'Sedang Diperiksa';
      case ServisStatus.dalam_perbaikan:
        return 'Dalam Perbaikan';
      case ServisStatus.menunggu_suku_cadang:
        return 'Menunggu Suku Cadang';
      case ServisStatus.ditolak:
        return 'Ditolak';
      case ServisStatus.menunggu_konfirmasi_owner:
        return 'Menunggu Konfirmasi Owner';
    }
  }

  Color get statusColor {
    switch (status) {
      case ServisStatus.menunggu_konfirmasi:
        return Colors.orange;
      case ServisStatus.ditugaskan:
        return Colors.blue;
      case ServisStatus.dikerjakan:
        return Colors.purple;
      case ServisStatus.selesai:
        return Colors.green;
      case ServisStatus.batal:
        return Colors.red;

    // legacy
      case ServisStatus.dalam_perjalanan:
        return Colors.cyan;
      case ServisStatus.tiba_di_lokasi:
        return Colors.orange;
      case ServisStatus.sedang_diperiksa:
        return Colors.purple;
      case ServisStatus.dalam_perbaikan:
        return Colors.purple;
      case ServisStatus.menunggu_suku_cadang:
        return Colors.yellow.shade700;
      case ServisStatus.ditolak:
        return Colors.red;
      case ServisStatus.menunggu_konfirmasi_owner:
        return Colors.amber;
    }
  }

  String get jenisDisplay {
    switch (jenis) {
      case JenisPenanganan.cuciAc:
        return 'Cuci AC';
      case JenisPenanganan.perbaikanAc:
        return 'Perbaikan AC';
      case JenisPenanganan.instalasi:
        return 'Instalasi AC';
    }
  }

  Color get jenisColor {
    switch (jenis) {
      case JenisPenanganan.cuciAc:
        return Colors.blue;
      case JenisPenanganan.perbaikanAc:
        return Colors.orange;
      case JenisPenanganan.instalasi:
        return Colors.green;
    }
  }

  IconData get jenisIcon {
    switch (jenis) {
      case JenisPenanganan.cuciAc:
        return Icons.clean_hands;
      case JenisPenanganan.perbaikanAc:
        return Icons.build;
      case JenisPenanganan.instalasi:
        return Icons.install_desktop;
    }
  }

  bool get isCompleted => status == ServisStatus.selesai;
  bool get isInProgress =>
      status == ServisStatus.ditugaskan || status == ServisStatus.dikerjakan;
  bool get requiresConfirmation => status == ServisStatus.menunggu_konfirmasi;
  bool get isRejected => status == ServisStatus.ditolak;
  bool get isCancelled => status == ServisStatus.batal;

  Duration? get duration {
    if (tanggalMulai == null || tanggalSelesai == null) return null;
    return tanggalSelesai!.difference(tanggalMulai!);
  }

  String? get durationDisplay {
    final dur = duration;
    if (dur == null) return null;
    if (dur.inHours < 1) return '${dur.inMinutes} menit';
    if (dur.inHours < 24) return '${dur.inHours} jam';
    return '${dur.inDays} hari';
  }

  String get formattedTotalBiaya => _formatCurrency(totalBiaya);
  String get formattedBiayaServis => _formatCurrency(biayaServis);
  String get formattedBiayaSukuCadang => _formatCurrency(biayaSukuCadang);

  static String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    )}';
  }

  // =====================
  // SERIALIZATION
  // =====================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'complaint_id': keluhanId,
      'location_id': lokasiId,
      'ac_unit_id': acId,
      'technician_id': teknisiId,
      'technician_ids': technicianIds,
      'jumlah_ac': jumlahAc,
      'jenis': _convertJenisToApi(jenis),
      'status': _convertStatusToApi(status),
      'tindakan': tindakan.map(_convertTindakanToApi).toList(),
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
      if (techniciansData.isNotEmpty) 'technicians': techniciansData,
      if (acUnitsDetail.isNotEmpty) 'ac_units_detail': acUnitsDetail,
      if (itemsData.isNotEmpty) 'items': itemsData,
    };
  }

  factory ServisModel.fromJson(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return ServisModel.fromMap(map);
  }

  String toJson() => jsonEncode(toMap());

  factory ServisModel.fromMap(Map<String, dynamic> map) {
    final String id = (map['id'] ?? '').toString();
    final String keluhanId =
    (map['complaint_id'] ?? map['keluhan_id'] ?? '').toString();
    final String lokasiId = (map['location_id'] ?? map['lokasi_id'] ?? '').toString();
    final String acId = (map['ac_unit_id'] ?? map['ac_id'] ?? '').toString();
    final String teknisiId =
    (map['technician_id'] ?? map['teknisi_id'] ?? '').toString();

    final int jumlahAC = (map['jumlah_ac'] is int)
        ? map['jumlah_ac'] as int
        : int.tryParse((map['jumlah_ac'] ?? '0').toString()) ?? 0;

    // --- items (service_items) ---
    List<Map<String, dynamic>> parsedItems = [];
    if (map['items'] is List) {
      parsedItems = (map['items'] as List)
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    // --- technicians array ---
    // di response kamu key-nya "teknisi": [] (bukan "technicians")
    List<Map<String, dynamic>> parsedTechnicians = [];
    if (map['technicians'] is List) {
      parsedTechnicians = (map['technicians'] as List)
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } else if (map['teknisi'] is List) {
      parsedTechnicians = (map['teknisi'] as List)
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    // --- ac_units_detail ---
    List<Map<String, dynamic>> parsedAcUnitsDetail = [];
    if (map['ac_units_detail'] is List) {
      parsedAcUnitsDetail = (map['ac_units_detail'] as List)
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    // --- parse technician_ids ---
    List<int>? parsedTechnicianIds;
    String? technicianIdsJson;

    if (map['technician_ids'] != null) {
      technicianIdsJson = map['technician_ids']?.toString();
      if (map['technician_ids'] is List) {
        parsedTechnicianIds = (map['technician_ids'] as List)
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((id) => id > 0)
            .toList();
      } else if (map['technician_ids'] is String) {
        final s = map['technician_ids'] as String;
        technicianIdsJson = s;
        try {
          if (s.trim().startsWith('[')) {
            final parsed = jsonDecode(s) as List;
            parsedTechnicianIds = parsed
                .map((e) => int.tryParse(e.toString()) ?? 0)
                .where((id) => id > 0)
                .toList();
          } else {
            final id = int.tryParse(s);
            if (id != null && id > 0) parsedTechnicianIds = [id];
          }
        } catch (_) {}
      }
    }

    // fallback: dari parsedTechnicians
    if ((parsedTechnicianIds == null || parsedTechnicianIds.isEmpty) &&
        parsedTechnicians.isNotEmpty) {
      final ids = parsedTechnicians
          .map((t) => int.tryParse((t['id'] ?? '').toString()) ?? 0)
          .where((id) => id > 0)
          .toList();
      if (ids.isNotEmpty) parsedTechnicianIds = ids;
    }

    // fallback: dari items[].technician_id
    if ((parsedTechnicianIds == null || parsedTechnicianIds.isEmpty) &&
        parsedItems.isNotEmpty) {
      final ids = parsedItems
          .map((it) => int.tryParse((it['technician_id'] ?? '').toString()) ?? 0)
          .where((id) => id > 0)
          .toSet()
          .toList();
      if (ids.isNotEmpty) parsedTechnicianIds = ids;
    }

    // fallback: single teknisiId
    if ((parsedTechnicianIds == null || parsedTechnicianIds.isEmpty) &&
        teknisiId.isNotEmpty) {
      final id = int.tryParse(teknisiId);
      if (id != null && id > 0) parsedTechnicianIds = [id];
    }

    // enums
    final ServisStatus status = _parseStatusFromApi(
        (map['status'] ?? 'menunggu_konfirmasi').toString());
    final JenisPenanganan jenis =
    _parseJenisFromApi((map['jenis'] ?? 'perbaikan').toString());

    final List<TindakanServis> tindakanList =
    _parseTindakanFromApi(map['tindakan'] as List<dynamic>? ?? []);

    List<String> parseFotoList(dynamic fotoData) {
      if (fotoData == null) return [];
      if (fotoData is List) return fotoData.map((e) => e.toString()).toList();
      return [];
    }

    return ServisModel(
      id: id,
      keluhanId: keluhanId,
      lokasiId: lokasiId,
      acId: acId,
      teknisiId: teknisiId,
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
      noInvoice: map['no_invoice']?.toString(),

      lokasiData: _convertToMap(map['lokasi']),
      acData: _convertToMap(map['ac']),
      teknisiData: _convertToMap(map['teknisi']),
      keluhanData: _convertToMap(map['keluhan']),

      techniciansData: parsedTechnicians,
      acUnitsDetail: parsedAcUnitsDetail,
      itemsData: parsedItems,
    );
  }

  // =====================
  // STATIC PARSERS
  // =====================
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static Map<String, dynamic>? _convertToMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    try {
      return DateTime.parse(dateValue.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  static DateTime? _parseNullableDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    try {
      return DateTime.parse(dateValue.toString());
    } catch (_) {
      return null;
    }
  }

  static ServisStatus _parseStatusFromApi(String status) {
    final s = status.toLowerCase();
    const map = {
      'menunggu_konfirmasi': ServisStatus.menunggu_konfirmasi,
      'ditugaskan': ServisStatus.ditugaskan,
      'dikerjakan': ServisStatus.dikerjakan,
      'selesai': ServisStatus.selesai,
      'batal': ServisStatus.batal,

      // legacy
      'dalam_perjalanan': ServisStatus.dalam_perjalanan,
      'tiba_di_lokasi': ServisStatus.tiba_di_lokasi,
      'sedang_diperiksa': ServisStatus.sedang_diperiksa,
      'dalam_perbaikan': ServisStatus.dalam_perbaikan,
      'menunggu_suku_cadang': ServisStatus.menunggu_suku_cadang,
      'ditolak': ServisStatus.ditolak,
      'menunggu_konfirmasi_owner': ServisStatus.menunggu_konfirmasi_owner,
    };
    return map[s] ?? ServisStatus.menunggu_konfirmasi;
  }

  static JenisPenanganan _parseJenisFromApi(String jenis) {
    final j = jenis.toLowerCase();
    const map = {
      'cuci': JenisPenanganan.cuciAc,
      'perbaikan': JenisPenanganan.perbaikanAc,
      'instalasi': JenisPenanganan.instalasi,
      'installasi': JenisPenanganan.instalasi, // safety
    };
    return map[j] ?? JenisPenanganan.perbaikanAc;
  }

  static List<TindakanServis> _parseTindakanFromApi(List<dynamic> tindakanList) {
    const tindakanMap = {
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
      case ServisStatus.menunggu_konfirmasi:
        return 'menunggu_konfirmasi';
      case ServisStatus.ditugaskan:
        return 'ditugaskan';
      case ServisStatus.dikerjakan:
        return 'dikerjakan';
      case ServisStatus.selesai:
        return 'selesai';
      case ServisStatus.batal:
        return 'batal';

    // legacy
      case ServisStatus.dalam_perjalanan:
        return 'dalam_perjalanan';
      case ServisStatus.tiba_di_lokasi:
        return 'tiba_di_lokasi';
      case ServisStatus.sedang_diperiksa:
        return 'sedang_diperiksa';
      case ServisStatus.dalam_perbaikan:
        return 'dalam_perbaikan';
      case ServisStatus.menunggu_suku_cadang:
        return 'menunggu_suku_cadang';
      case ServisStatus.ditolak:
        return 'ditolak';
      case ServisStatus.menunggu_konfirmasi_owner:
        return 'menunggu_konfirmasi_owner';
    }
  }

  static String _convertJenisToApi(JenisPenanganan jenis) {
    switch (jenis) {
      case JenisPenanganan.cuciAc:
        return 'cuci';
      case JenisPenanganan.perbaikanAc:
        return 'perbaikan';
      case JenisPenanganan.instalasi:
        return 'instalasi';
    }
  }

  static String _convertTindakanToApi(TindakanServis tindakan) {
    switch (tindakan) {
      case TindakanServis.pembersihan:
        return 'pembersihan';
      case TindakanServis.isiFreon:
        return 'isi_freon';
      case TindakanServis.gantiFilter:
        return 'ganti_filter';
      case TindakanServis.perbaikanKompressor:
        return 'perbaikan_kompressor';
      case TindakanServis.perbaikanPCB:
        return 'perbaikan_pcb';
      case TindakanServis.gantiKapasitor:
        return 'ganti_kapasitor';
      case TindakanServis.gantiFanMotor:
        return 'ganti_fan_motor';
      case TindakanServis.tuneUp:
        return 'tune_up';
      case TindakanServis.lainnya:
        return 'lainnya';
    }
  }

  // =====================
  // FORMAT DATE (optional)
  // =====================
  static String formatDateTimeId(DateTime date) {
    final dayNames = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dayNames[date.weekday % 7]}, ${date.day} ${monthNames[date.month - 1]} ${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get statusKeyFromItems {
    // itemsData sudah difilter oleh backend hanya milik teknisi login
    if (itemsData.isEmpty) return status.name.toLowerCase(); // fallback

    final statuses = itemsData
        .map((it) => (it['status'] ?? '').toString().toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (statuses.isEmpty) return status.name.toLowerCase();

    // aturan prioritas:
    // jika ada dikerjakan => dikerjakan
    // jika semua selesai => selesai
    // sisanya => ditugaskan
    if (statuses.contains('dikerjakan')) return 'dikerjakan';
    if (statuses.every((s) => s == 'selesai')) return 'selesai';
    return 'ditugaskan';
  }

  int get jumlahAcFromItems => itemsData.length;

  List<String> get acUnitsNamesFromItemsOnly {
    return itemsData
        .map((it) => it['ac_unit'])
        .where((u) => u is Map)
        .map((u) => (u as Map)['name']?.toString().trim() ?? '')
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();
  }


  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ServisModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

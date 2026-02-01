// lib/models/servis_model.dart
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
  final List<String> fotoSesudah;
  final List<String> fotoSukuCadang;

  final DateTime tanggalDitugaskan;
  final DateTime? tanggalMulai;
  final DateTime? tanggalSelesai;
  final DateTime? tanggalDikonfirmasi;

  final double biayaServis;
  final double biayaSukuCadang;

  final String? noInvoice;

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
    this.fotoSesudah = const [],
    this.fotoSukuCadang = const [],
    required this.tanggalDitugaskan,
    this.tanggalMulai,
    this.tanggalSelesai,
    this.tanggalDikonfirmasi,
    this.biayaServis = 0,
    this.biayaSukuCadang = 0,
    this.noInvoice,
  });

  double get totalBiaya => biayaServis + biayaSukuCadang;

  ServisModel copyWith({
    String? id,
    String? keluhanId,
    String? lokasiId,
    String? acId,
    String? teknisiId,
    ServisStatus? status,
    List<TindakanServis>? tindakan,
    String? diagnosa,
    String? catatan,
    List<String>? fotoSebelum,
    List<String>? fotoSesudah,
    List<String>? fotoSukuCadang,
    DateTime? tanggalDitugaskan,
    DateTime? tanggalMulai,
    DateTime? tanggalSelesai,
    DateTime? tanggalDikonfirmasi,
    double? biayaServis,
    double? biayaSukuCadang,
    String? noInvoice,
  }) {
    return ServisModel(
      id: id ?? this.id,
      keluhanId: keluhanId ?? this.keluhanId,
      lokasiId: lokasiId ?? this.lokasiId,
      acId: acId ?? this.acId,
      teknisiId: teknisiId ?? this.teknisiId,
      status: status ?? this.status,
      tindakan: tindakan ?? this.tindakan,
      diagnosa: diagnosa ?? this.diagnosa,
      catatan: catatan ?? this.catatan,
      fotoSebelum: fotoSebelum ?? this.fotoSebelum,
      fotoSesudah: fotoSesudah ?? this.fotoSesudah,
      fotoSukuCadang: fotoSukuCadang ?? this.fotoSukuCadang,
      tanggalDitugaskan: tanggalDitugaskan ?? this.tanggalDitugaskan,
      tanggalMulai: tanggalMulai ?? this.tanggalMulai,
      tanggalSelesai: tanggalSelesai ?? this.tanggalSelesai,
      tanggalDikonfirmasi: tanggalDikonfirmasi ?? this.tanggalDikonfirmasi,
      biayaServis: biayaServis ?? this.biayaServis,
      biayaSukuCadang: biayaSukuCadang ?? this.biayaSukuCadang,
      noInvoice: noInvoice ?? this.noInvoice,
    );
  }

  /// Simpan enum sebagai String biar gampang di Firestore/REST
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'keluhanId': keluhanId,
      'lokasiId': lokasiId,
      'acId': acId,
      'teknisiId': teknisiId,
      'status': status.name,
      'tindakan': tindakan.map((e) => e.name).toList(),
      'diagnosa': diagnosa,
      'catatan': catatan,
      'fotoSebelum': fotoSebelum,
      'fotoSesudah': fotoSesudah,
      'fotoSukuCadang': fotoSukuCadang,
      'tanggalDitugaskan': tanggalDitugaskan.toIso8601String(),
      'tanggalMulai': tanggalMulai?.toIso8601String(),
      'tanggalSelesai': tanggalSelesai?.toIso8601String(),
      'tanggalDikonfirmasi': tanggalDikonfirmasi?.toIso8601String(),
      'biayaServis': biayaServis,
      'biayaSukuCadang': biayaSukuCadang,
      'noInvoice': noInvoice,
    };
  }

  static ServisModel fromMap(Map<String, dynamic> map) {
    return ServisModel(
      id: map['id'] as String,
      keluhanId: map['keluhanId'] as String,
      lokasiId: map['lokasiId'] as String,
      acId: map['acId'] as String,
      teknisiId: map['teknisiId'] as String,
      status: ServisStatus.values.byName(map['status'] as String),
      tindakan: (map['tindakan'] as List<dynamic>? ?? [])
          .map((e) => TindakanServis.values.byName(e as String))
          .toList(),
      diagnosa: (map['diagnosa'] ?? '') as String,
      catatan: (map['catatan'] ?? '') as String,
      fotoSebelum: (map['fotoSebelum'] as List<dynamic>? ?? []).cast<String>(),
      fotoSesudah: (map['fotoSesudah'] as List<dynamic>? ?? []).cast<String>(),
      fotoSukuCadang: (map['fotoSukuCadang'] as List<dynamic>? ?? []).cast<String>(),
      tanggalDitugaskan: DateTime.parse(map['tanggalDitugaskan'] as String),
      tanggalMulai: map['tanggalMulai'] == null ? null : DateTime.parse(map['tanggalMulai'] as String),
      tanggalSelesai: map['tanggalSelesai'] == null ? null : DateTime.parse(map['tanggalSelesai'] as String),
      tanggalDikonfirmasi: map['tanggalDikonfirmasi'] == null ? null : DateTime.parse(map['tanggalDikonfirmasi'] as String),
      biayaServis: (map['biayaServis'] ?? 0).toDouble(),
      biayaSukuCadang: (map['biayaSukuCadang'] ?? 0).toDouble(),
      noInvoice: map['noInvoice'] as String?,
    );
  }
}

import 'package:flutter/material.dart';
import '../models/servis_model.dart';

extension ServisStatusX on ServisStatus {
  String get text {
    switch (this) {
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

  Color get color {
    switch (this) {
      case ServisStatus.ditugaskan: return Colors.blue;
      case ServisStatus.dalamPerjalanan: return Colors.orange;
      case ServisStatus.tibaDiLokasi: return Colors.purple;
      case ServisStatus.sedangDiperiksa: return Colors.indigo;
      case ServisStatus.dalamPerbaikan: return Colors.red;
      case ServisStatus.menungguSukuCadang: return Colors.amber;
      case ServisStatus.selesai: return Colors.green;
      case ServisStatus.ditolak: return Colors.red.shade900;
      case ServisStatus.menungguKonfirmasi: return Colors.yellow.shade700;
    }
  }

  String get shortText {
    switch (this) {
      case ServisStatus.ditugaskan: return 'Tugas';
      case ServisStatus.dalamPerjalanan: return 'Jalan';
      case ServisStatus.tibaDiLokasi: return 'Tiba';
      case ServisStatus.sedangDiperiksa: return 'Periksa';
      case ServisStatus.dalamPerbaikan: return 'Perbaiki';
      case ServisStatus.menungguSukuCadang: return 'Tunggu';
      case ServisStatus.menungguKonfirmasi: return 'Konfirm';
      case ServisStatus.selesai: return 'Selesai';
      case ServisStatus.ditolak: return 'Tolak';
    }
  }
}

extension TindakanServisX on TindakanServis {
  String get text {
    switch (this) {
      case TindakanServis.pembersihan: return 'Pembersihan';
      case TindakanServis.isiFreon: return 'Isi Freon';
      case TindakanServis.gantiFilter: return 'Ganti Filter';
      case TindakanServis.perbaikanKompressor: return 'Perbaikan Kompressor';
      case TindakanServis.perbaikanPCB: return 'Perbaikan PCB';
      case TindakanServis.gantiKapasitor: return 'Ganti Kapasitor';
      case TindakanServis.gantiFanMotor: return 'Ganti Fan Motor';
      case TindakanServis.tuneUp: return 'Tune Up';
      case TindakanServis.lainnya: return 'Lainnya';
    }
  }
}

extension ServisModelX on ServisModel {
  String get statusTextUI => status.text;
  Color get statusColorUI => status.color;

  String get tindakanTextUI {
    if (tindakan.isEmpty) return 'Belum ditentukan';
    return tindakan.map((e) => e.text).join(', ');
  }
}

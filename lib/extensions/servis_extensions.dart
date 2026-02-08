import 'package:flutter/material.dart';
import '../models/servis_model.dart';

extension ServisStatusX on ServisStatus {
  String get text {
    switch (this) {
      case ServisStatus.ditugaskan: return 'Ditugaskan';
      case ServisStatus.dalam_perjalanan: return 'Dalam Perjalanan';
      case ServisStatus.tiba_di_lokasi: return 'Tiba di Lokasi';
      case ServisStatus.sedang_diperiksa: return 'Sedang Diperiksa';
      case ServisStatus.dalam_perbaikan: return 'Dalam Perbaikan';
      case ServisStatus.menunggu_suku_cadang: return 'Menunggu Suku Cadang';
      case ServisStatus.selesai: return 'Selesai';
      case ServisStatus.ditolak: return 'Ditolak';
      case ServisStatus.menunggu_konfirmasi: return 'Menunggu Konfirmasi';
      case ServisStatus.dikerjakan:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ServisStatus.batal:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ServisStatus.menunggu_konfirmasi_owner:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  Color get color {
    switch (this) {
      case ServisStatus.ditugaskan: return Colors.blue;
      case ServisStatus.dalam_perjalanan: return Colors.orange;
      case ServisStatus.tiba_di_lokasi: return Colors.purple;
      case ServisStatus.sedang_diperiksa: return Colors.indigo;
      case ServisStatus.dalam_perbaikan: return Colors.red;
      case ServisStatus.menunggu_suku_cadang: return Colors.amber;
      case ServisStatus.selesai: return Colors.green;
      case ServisStatus.ditolak: return Colors.red.shade900;
      case ServisStatus.menunggu_konfirmasi: return Colors.yellow.shade700;
      case ServisStatus.dikerjakan:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ServisStatus.batal:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ServisStatus.menunggu_konfirmasi_owner:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  String get shortText {
    switch (this) {
      case ServisStatus.ditugaskan: return 'Tugas';
      case ServisStatus.dalam_perjalanan: return 'Jalan';
      case ServisStatus.tiba_di_lokasi: return 'Tiba';
      case ServisStatus.sedang_diperiksa: return 'Periksa';
      case ServisStatus.dalam_perbaikan: return 'Perbaiki';
      case ServisStatus.menunggu_suku_cadang: return 'Tunggu';
      case ServisStatus.menunggu_konfirmasi: return 'Konfirm';
      case ServisStatus.selesai: return 'Selesai';
      case ServisStatus.ditolak: return 'Tolak';
      case ServisStatus.dikerjakan:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ServisStatus.batal:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ServisStatus.menunggu_konfirmasi_owner:
        // TODO: Handle this case.
        throw UnimplementedError();
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

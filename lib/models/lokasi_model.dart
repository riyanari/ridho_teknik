import 'package:ridho_teknik/models/user_model.dart';

class LokasiModel {
  final String id;
  final String nama;
  final String alamat;
  final int jumlahAC;
  final DateTime lastService;
  final List<UserModel>? users;

  LokasiModel({
    required this.id,
    required this.nama,
    required this.alamat,
    this.jumlahAC = 0,
    required this.lastService,
    this.users,
  });

  factory LokasiModel.fromJson(Map<String, dynamic> json) {
    return LokasiModel(
      id: json['id'].toString(),
      nama: json['name'] ?? '',
      alamat: json['address'] ?? '',
      jumlahAC: json['jumlah_ac'] ?? json['ac_units_count'] ?? 0,
      lastService: json['last_service'] != null
          ? DateTime.tryParse(json['last_service']) ?? DateTime.now()
          : DateTime.now(),
      // Ambil data dari 'users' yang ada di dalam JSON dan ubah menjadi objek UserModel
      users: json['users'] != null
          ? (json['users'] as List)
          .map((userJson) => UserModel.fromJson(userJson))
          .toList()
          : [], // Jika tidak ada user, simpan null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': nama,
      'address': alamat,
      'jumlah_ac': jumlahAC,
      'last_service': lastService.toIso8601String(),
      'users': users?.map((user) => user.toJson()).toList(), // Perbaiki ini
    };
  }
}

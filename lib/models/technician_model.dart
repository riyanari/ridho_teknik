class Technician {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String spesialisasi;
  final double rating;
  final int totalService;
  final DateTime? createdAt;
  final String status; // lokal saja

  Technician({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.spesialisasi,
    required this.rating,
    required this.totalService,
    this.createdAt,
    this.status = 'aktif',
  });

  factory Technician.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return Technician(
      id: parseInt(json['id']),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: (json['role'] ?? 'teknisi').toString(),
      spesialisasi:
      (json['spesialisasi'] ?? 'AC Umum').toString(),
      rating: parseDouble(json['rating']),
      totalService: parseInt(json['total_service']),
      createdAt: parseDate(json['created_at']),
      status: (json['status'] ?? 'aktif').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'spesialisasi': spesialisasi,
    'rating': rating,
    'total_service': totalService,
    'created_at': createdAt?.toIso8601String(),
    'status': status,
  };
}
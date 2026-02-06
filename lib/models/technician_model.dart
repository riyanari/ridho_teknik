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
  final String status; // aktif, nonaktif, cuti

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
    return Technician(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'teknisi',
      spesialisasi: json['spesialisasi'] ?? 'AC Umum',
      rating: (json['rating'] ?? 0).toDouble(),
      totalService: json['total_service'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      status: json['status'] ?? 'aktif',
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
class Client {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final int totalService;
  final double rating;
  final String? spesialisasi;
  final DateTime? createdAt;

  Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.totalService,
    required this.rating,
    this.spesialisasi,
    this.createdAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'client',
      totalService: json['total_service'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      spesialisasi: json['spesialisasi'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'total_service': totalService,
    'rating': rating,
    'spesialisasi': spesialisasi,
    'created_at': createdAt?.toIso8601String(),
  };
}
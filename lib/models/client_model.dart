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
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final text = value.toString();
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    return Client(
      id: parseInt(json['id']),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: (json['role'] ?? 'client').toString(),
      totalService: parseInt(json['total_service']),
      rating: parseDouble(json['rating']),
      spesialisasi: json['spesialisasi']?.toString(),
      createdAt: parseDate(json['created_at']),
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
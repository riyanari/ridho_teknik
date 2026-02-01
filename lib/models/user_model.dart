class UserModel {
  final int? id;
  final String? name;
  final String? email;
  final String? role; // optional: teknisi/admin/client kalau kamu pakai

  String? token; // simpan Bearer token di sini (mutable)

  UserModel({
    this.id,
    this.name,
    this.email,
    this.role,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _toInt(json['id']),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      role: json['role']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
    };
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}

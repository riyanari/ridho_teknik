class UserModel {
  final int? id;
  final String? name;
  final String? email;
  final String? role;
  final String? phone;

  String? token;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.role,
    this.phone,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _toInt(json['id']),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      role: json['role']?.toString(),
      phone: (
          json['phone'] ??
              json['no_hp'] ??
              json['phone_number'] ??
              json['whatsapp']
      )?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
    };
  }

  bool get hasPhone {
    return phone != null &&
        phone!.trim().isNotEmpty;
  }

  String get phoneDisplay {
    final value = phone?.trim() ?? '';

    if (value.isEmpty) {
      return '-';
    }

    return value;
  }

  String get whatsappNumber {
    var value = phone?.trim() ?? '';

    if (value.isEmpty) {
      return '';
    }

    value = value.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (value.startsWith('0')) {
      value = '62${value.substring(1)}';
    } else if (value.startsWith('8')) {
      value = '62$value';
    }

    return value;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;

    if (v is int) {
      return v;
    }

    return int.tryParse(
      v.toString(),
    );
  }
}
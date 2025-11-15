class UserModel {
  final int id; // ✅ Đổi từ String sang int
  final String username;
  final String email;
  final String? fullName;
  final String? phone;
  final String? address;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.phone,
    this.address,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is String
          ? int.parse(json['id'])
          : json['id'], // ✅ Parse nếu là String
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'],
      phone: json['phone'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'address': address,
    };
  }

  // ✅ Sửa copyWith
  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? fullName,
    String? phone,
    String? address,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }
}

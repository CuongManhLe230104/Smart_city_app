class UserModel {
  final int id;
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
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      username: json['username'] ?? json['email']?.split('@')[0] ?? '',
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

  String getDisplayName() {
    if (fullName != null && fullName!.isNotEmpty) {
      return fullName!;
    }
    return email;
  }

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

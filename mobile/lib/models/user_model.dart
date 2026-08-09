class UserModel {
  final int id;
  final String email;
  final String fullName;
  final String role;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      role: json['role'] ?? 'resident',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
    };
  }
}

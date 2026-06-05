class User {
  final int userId;
  final String fullName;
  final String email;
  final String role;

  User({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      fullName: json['full_name'],
      email: json['email'],
      role: json['role'],
    );
  }
}
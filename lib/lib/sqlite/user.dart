// lib/sqlite/user.dart
class User {
  int? id;
  String email;
  String password;
  String createdAt;
  String updatedAt;

  User({
    this.id,
    required this.email,
    required this.password,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert a User into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Convert a Map into a User
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      password: map['password'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}

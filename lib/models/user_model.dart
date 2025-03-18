class UserModel {
  final String name;
  final String email;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  UserModel({
    required this.name,
    required this.email,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  // Create a UserModel from a map (useful for JSON parsing)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      status: map['status'] ?? 'Active',
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  // Convert UserModel to a map (useful for storage)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create a copy of this UserModel with some updated fields
  UserModel copyWith({
    String? name,
    String? email,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(name: $name, email: $email, status: $status)';
  }
}
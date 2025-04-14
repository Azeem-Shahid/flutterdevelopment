class UserModel {
  final String name;
  final String email;
  final String password;
  final String city;
  final String address;
  final String gender;
  final String? imagePath;

  UserModel({
    required this.name,
    required this.email,
    required this.password,
    required this.city,
    required this.address,
    required this.gender,
    this.imagePath,
  });

  // Convert a UserModel into a Map (for JSON serialization)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'city': city,
      'address': address,
      'gender': gender,
      'imagePath': imagePath,
    };
  }

  // Create a UserModel from a Map (for JSON deserialization)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      gender: json['gender'] ?? '',
      imagePath: json['imagePath'],
    );
  }

  // Create a copy of this UserModel with some fields replaced
  UserModel copyWith({
    String? name,
    String? email,
    String? password,
    String? city,
    String? address,
    String? gender,
    String? imagePath,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      city: city ?? this.city,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  String toString() {
    return 'UserModel(name: $name, email: $email, city: $city, gender: $gender)';
  }
}
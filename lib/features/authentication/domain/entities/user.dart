class User {
  final String id;
  final String name;
  final String phoneNumber;
  final String? token;

  User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'token': token,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      token: token ?? this.token,
    );
  }
} 
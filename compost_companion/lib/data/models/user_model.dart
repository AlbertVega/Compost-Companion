class User {
  final String username;
  final String email;
  final String? country;
  final String? location;
  final String? createdAt;

  User({
    required this.username,
    required this.email,
    this.country,
    this.location,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] as String,
      email: json['email'] as String,
      country: json['country'] as String?,
      location: json['location'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'country': country,
      'location': location,
    };
  }
}

class UserCreate {
  final String username;
  final String email;
  final String password;
  final String? country;
  final String? location;

  UserCreate({
    required this.username,
    required this.email,
    required this.password,
    this.country,
    this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'country': country,
      'location': location,
    };
  }
}

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

class CompostPile {
  final int id;
  final String username;
  final String name;
  final double? volumeAtCreation;
  final String? location;
  final DateTime createdAt;

  CompostPile({
    required this.id,
    required this.username,
    required this.name,
    this.volumeAtCreation,
    this.location,
    required this.createdAt,
  });

  factory CompostPile.fromJson(Map<String, dynamic> json) {
    return CompostPile(
      id: json['pile_id'] ?? json['id'] ?? 0,
      username: json['username'] as String,
      name: json['name'] as String,
      volumeAtCreation: json['volume_at_creation'] != null
          ? (json['volume_at_creation'] as num).toDouble()
          : null,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

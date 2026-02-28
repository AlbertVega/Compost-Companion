class Ingredient {
  final String name;
  final double? moistureContent;
  final double? nitrogenContent;
  final double? carbonContent;

  Ingredient({
    required this.name,
    this.moistureContent,
    this.nitrogenContent,
    this.carbonContent,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] as String,
      moistureContent: json['moisture_content'] != null
          ? (json['moisture_content'] as num).toDouble()
          : null,
      nitrogenContent: json['nitrogen_content'] != null
          ? (json['nitrogen_content'] as num).toDouble()
          : null,
      carbonContent: json['carbon_content'] != null
          ? (json['carbon_content'] as num).toDouble()
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ingredient &&
        runtimeType == other.runtimeType &&
        name == other.name &&
        moistureContent == other.moistureContent &&
        nitrogenContent == other.nitrogenContent &&
        carbonContent == other.carbonContent;
  }

  @override
  int get hashCode {
    return Object.hash(name, moistureContent, nitrogenContent, carbonContent);
  }
}

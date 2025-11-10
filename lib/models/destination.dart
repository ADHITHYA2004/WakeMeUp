/// Model representing a destination with coordinates and metadata
class Destination {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  Destination({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert Destination to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create Destination from Map (database retrieval)
  factory Destination.fromMap(Map<String, dynamic> map) {
    return Destination(
      id: map['id'] as int?,
      name: map['name'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Create a copy with updated fields
  Destination copyWith({
    int? id,
    String? name,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return Destination(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}


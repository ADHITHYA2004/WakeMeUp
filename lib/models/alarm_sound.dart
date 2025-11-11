/// Represents an alarm sound option (default or custom)
class AlarmSound {
  final String id;
  final String name;
  final String? assetPath; // For default sounds from assets
  final String? filePath; // For custom sounds from device
  final bool isDefault;

  AlarmSound({
    required this.id,
    required this.name,
    this.assetPath,
    this.filePath,
    this.isDefault = true,
  }) : assert(
          (assetPath != null && filePath == null) ||
              (assetPath == null && filePath != null),
          'AlarmSound must have either assetPath or filePath',
        );

  /// Get the sound path (asset or file)
  String? get soundPath => assetPath ?? filePath;

  /// Check if this is a custom sound
  bool get isCustom => !isDefault;

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'assetPath': assetPath,
      'filePath': filePath,
      'isDefault': isDefault,
    };
  }

  /// Create from map
  factory AlarmSound.fromMap(Map<String, dynamic> map) {
    return AlarmSound(
      id: map['id'] as String,
      name: map['name'] as String,
      assetPath: map['assetPath'] as String?,
      filePath: map['filePath'] as String?,
      isDefault: map['isDefault'] as bool? ?? true,
    );
  }

  /// Create a copy with updated fields
  AlarmSound copyWith({
    String? id,
    String? name,
    String? assetPath,
    String? filePath,
    bool? isDefault,
  }) {
    return AlarmSound(
      id: id ?? this.id,
      name: name ?? this.name,
      assetPath: assetPath ?? this.assetPath,
      filePath: filePath ?? this.filePath,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}


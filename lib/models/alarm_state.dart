import 'destination.dart';

/// Represents the current state of an active alarm
class AlarmState {
  final Destination destination;
  final double alertDistance; // in meters
  final double? currentDistance; // in meters
  final bool isActive;
  final DateTime? startedAt;

  AlarmState({
    required this.destination,
    required this.alertDistance,
    this.currentDistance,
    this.isActive = false,
    this.startedAt,
  });

  /// Create a copy with updated fields
  AlarmState copyWith({
    Destination? destination,
    double? alertDistance,
    double? currentDistance,
    bool? isActive,
    DateTime? startedAt,
  }) {
    return AlarmState(
      destination: destination ?? this.destination,
      alertDistance: alertDistance ?? this.alertDistance,
      currentDistance: currentDistance ?? this.currentDistance,
      isActive: isActive ?? this.isActive,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  /// Check if alarm should trigger (user within alert distance)
  bool shouldTrigger() {
    if (currentDistance == null) return false;
    return currentDistance! <= alertDistance;
  }
}


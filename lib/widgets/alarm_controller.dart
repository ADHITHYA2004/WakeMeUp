import 'package:flutter/material.dart';
import '../models/destination.dart';
import '../models/alarm_state.dart';
import '../services/alarm_service.dart';

/// Reusable controller widget for managing alarm state and updates
/// This component handles alarm logic and can be used across screens
class AlarmController extends StatefulWidget {
  final Destination destination;
  final double alertDistance;
  final Widget Function(AlarmState?) builder;

  const AlarmController({
    super.key,
    required this.destination,
    required this.alertDistance,
    required this.builder,
  });

  @override
  State<AlarmController> createState() => _AlarmControllerState();
}

class _AlarmControllerState extends State<AlarmController> {
  AlarmState? _alarmState;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAlarm();
  }

  /// Initialize alarm and set up update listener
  Future<void> _initializeAlarm() async {
    await AlarmService.instance.startAlarm(
      widget.destination,
      widget.alertDistance,
      _onAlarmUpdate,
    );
    setState(() {
      _isInitialized = true;
    });
  }

  /// Handle alarm state updates
  void _onAlarmUpdate(AlarmState state) {
    if (mounted) {
      setState(() {
        _alarmState = state;
      });
    }
  }

  /// Stop the alarm
  Future<void> stopAlarm() async {
    await AlarmService.instance.stopAlarm();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return widget.builder(_alarmState);
  }

  @override
  void dispose() {
    // Note: We don't stop alarm here as it might be needed elsewhere
    // Call stopAlarm() explicitly when needed
    super.dispose();
  }
}


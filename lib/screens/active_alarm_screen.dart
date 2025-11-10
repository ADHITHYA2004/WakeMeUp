import 'package:flutter/material.dart';
import 'dart:async';
import '../models/destination.dart';
import '../models/alarm_state.dart';
import '../services/alarm_service.dart';

/// Screen showing active alarm with live distance updates
class ActiveAlarmScreen extends StatefulWidget {
  const ActiveAlarmScreen({super.key});

  @override
  State<ActiveAlarmScreen> createState() => _ActiveAlarmScreenState();
}

class _ActiveAlarmScreenState extends State<ActiveAlarmScreen> {
  AlarmState? _alarmState;
  Timer? _updateTimer;
  Destination? _destination;
  double? _alertDistance;

  @override
  void initState() {
    super.initState();
    // Don't access context-dependent widgets here
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Access route arguments here, after context is ready
    if (_destination == null && _alertDistance == null) {
      _initializeAlarm();
    }
  }

  /// Initialize alarm from route arguments or active alarm service
  void _initializeAlarm() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _destination = args['destination'] as Destination?;
      _alertDistance = args['alertDistance'] as double?;
    }

    // Get current alarm state from service
    _alarmState = AlarmService.instance.getCurrentAlarm();
    if (_alarmState == null && _destination != null && _alertDistance != null) {
      _alarmState = AlarmState(
        destination: _destination!,
        alertDistance: _alertDistance!,
        isActive: true,
        startedAt: DateTime.now(),
      );
    }

    // Set up update listener
    _startUpdateTimer();
  }

  /// Start timer to periodically update alarm state
  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final currentAlarm = AlarmService.instance.getCurrentAlarm();
      if (currentAlarm != null) {
        setState(() {
          _alarmState = currentAlarm;
        });
      }
    });
  }

  /// Cancel the alarm
  Future<void> _cancelAlarm() async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Cancel Alarm'),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel this alarm?',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AlarmService.instance.stopAlarm();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  /// Format distance for display
  String _formatDistance(double? distance) {
    if (distance == null) return 'Calculating...';
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)}km';
    }
  }

  @override
  Widget build(BuildContext context) {
    final distance = _alarmState?.currentDistance;
    final isWithinRange = _alarmState?.shouldTrigger() ?? false;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Alarm'),
        backgroundColor: isWithinRange ? Colors.red.shade600 : colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _cancelAlarm,
            tooltip: 'Cancel Alarm',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isWithinRange
                ? [
                    Colors.red.shade500,
                    Colors.orange.shade500,
                  ]
                : isDark
                    ? [
                        const Color(0xFF0F172A).withOpacity(0.3),
                        const Color(0xFF1E293B).withOpacity(0.3),
                      ]
                    : [
                        colorScheme.primary.withOpacity(0.05),
                        colorScheme.secondary.withOpacity(0.05),
                      ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Animated alarm icon with pulse effect
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: isWithinRange ? 1.15 : 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                  builder: (context, scale, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: isWithinRange
                              ? [
                                  Colors.red.withOpacity(0.3),
                                  Colors.red.withOpacity(0.1),
                                ]
                              : [
                                  colorScheme.primary.withOpacity(0.2),
                                  colorScheme.primary.withOpacity(0.05),
                                ],
                        ),
                        boxShadow: isWithinRange
                            ? [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.5),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ]
                            : [],
                      ),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isWithinRange
                                ? Colors.red.shade50
                                : Colors.white.withOpacity(0.9),
                            boxShadow: [
                              BoxShadow(
                                color: (isWithinRange
                                        ? Colors.red
                                        : colorScheme.primary)
                                    .withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            isWithinRange
                                ? Icons.warning_rounded
                                : Icons.location_on_rounded,
                            size: 100,
                            color: isWithinRange
                                ? Colors.red.shade700
                                : colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                // Status text with animation
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isWithinRange ? Colors.red.shade700 : null,
                        letterSpacing: isWithinRange ? 2 : 0,
                      ),
                  child: Text(
                    isWithinRange ? 'ALARM TRIGGERED!' : 'Tracking Active',
                  ),
                ),
                const SizedBox(height: 20),
                // Destination name
                if (_alarmState?.destination != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.place_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _alarmState!.destination.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 48),
                // Distance card with modern design
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                        blurRadius: 30,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Text(
                        'Distance to Destination',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _formatDistance(distance),
                          key: ValueKey(distance),
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isWithinRange
                                    ? Colors.red.shade600
                                    : colorScheme.primary,
                                fontSize: 48,
                              ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_active_rounded,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Alert at: ${_formatDistance(_alarmState?.alertDistance)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Cancel button with modern design
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _cancelAlarm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 64),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stop_rounded, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Cancel Alarm',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}


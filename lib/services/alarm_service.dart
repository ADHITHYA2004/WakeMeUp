import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/destination.dart';
import '../models/alarm_state.dart';
import '../models/alarm_sound.dart';
import 'location_service.dart';
import 'sound_service.dart';

/// Service to manage alarm functionality (notifications, vibration, tracking)
class AlarmService {
  static final AlarmService instance = AlarmService._init();
  AlarmService._init();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<Position>? _positionSubscription;
  AlarmState? _currentAlarm;
  Function(AlarmState)? _onAlarmUpdate;

  /// Initialize notification plugin
  Future<void> initialize() async {
    if (kIsWeb) {
      // Notifications not fully supported on web, skip initialization
      return;
    }

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions
      await _requestPermissions();
    } catch (e) {
      // Initialization failed, continue anyway
      debugPrint('Notification initialization failed: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap if needed
  }

  /// Start tracking and monitoring alarm
  Future<void> startAlarm(
    Destination destination,
    double alertDistance,
    Function(AlarmState) onUpdate, {
    AlarmSound? alarmSound,
  }) async {
    // Stop any existing alarm first
    await stopAlarm();
    
    _currentAlarm = AlarmState(
      destination: destination,
      alertDistance: alertDistance,
      isActive: true,
      startedAt: DateTime.now(),
      alarmSound: alarmSound,
    );
    _onAlarmUpdate = onUpdate;

    // Start listening to position updates
    _positionSubscription = LocationService.instance
        .getPositionStream()
        .listen(_onPositionUpdate);

    // Initial update
    final position = await LocationService.instance.getCurrentPosition();
    if (position != null) {
      _onPositionUpdate(position);
    }
  }

  /// Handle position updates and check if alarm should trigger
  void _onPositionUpdate(Position position) {
    if (_currentAlarm == null) return;

    final distance = LocationService.calculateDistance(
      position.latitude,
      position.longitude,
      _currentAlarm!.destination.latitude,
      _currentAlarm!.destination.longitude,
    );

    _currentAlarm = _currentAlarm!.copyWith(currentDistance: distance);

    // Notify listeners
    _onAlarmUpdate?.call(_currentAlarm!);

    // Check if alarm should trigger
    if (_currentAlarm!.shouldTrigger() && _currentAlarm!.isActive) {
      _triggerAlarm();
    }
  }

  /// Trigger the alarm (sound + vibration + notification)
  Future<void> _triggerAlarm() async {
    if (_currentAlarm == null) return;

    // Cancel alarm to prevent multiple triggers
    _currentAlarm = _currentAlarm!.copyWith(isActive: false);

    // Play selected alarm sound
    if (_currentAlarm!.alarmSound != null) {
      try {
        await SoundService.instance.playAlarmSound(_currentAlarm!.alarmSound!);
      } catch (e) {
        debugPrint('Error playing alarm sound: $e');
      }
    }

    if (!kIsWeb) {
      // Vibrate (not available on web)
      try {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 2000);
        }
      } catch (e) {
        debugPrint('Vibration failed: $e');
      }

      // Show notification (not fully supported on web)
      try {
        await _notifications.show(
          0,
          'Wake Up! 🚨',
          'You are approaching your destination: ${_currentAlarm!.destination.name}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'wakemeup_channel',
              'WakeMeUp Alarms',
              channelDescription: 'Notifications for destination alarms',
              importance: Importance.high,
              priority: Priority.high,
              playSound: false, // We're playing sound separately
              enableVibration: true,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: false, // We're playing sound separately
            ),
          ),
        );
      } catch (e) {
        debugPrint('Notification failed: $e');
      }
    } else {
      // On web, use browser alert
      // Note: This requires user interaction, so it may not work in all cases
      debugPrint('ALARM TRIGGERED: Approaching ${_currentAlarm!.destination.name}');
    }

    // Stop tracking
    await stopAlarm();
  }

  /// Stop the alarm and cancel tracking
  Future<void> stopAlarm() async {
    // Stop any playing alarm sound
    await SoundService.instance.stopAlarmSound();
    
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _currentAlarm = null;
    _onAlarmUpdate = null;
  }

  /// Get current alarm state
  AlarmState? getCurrentAlarm() => _currentAlarm;

  /// Check if alarm is active
  bool isAlarmActive() => _currentAlarm?.isActive ?? false;
}


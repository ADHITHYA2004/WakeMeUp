import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_sound.dart';

/// Service to manage alarm sounds (default and custom)
class SoundService {
  static final SoundService instance = SoundService._init();
  SoundService._init();

  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Web-only in-memory cache (avoid localStorage quota)
  static final Map<String, String> _webSoundCache = {}; // id -> base64
  static final List<AlarmSound> _webCustomList = [];
  
  // Default alarm sounds
  static final List<AlarmSound> _defaultSounds = [
    AlarmSound(
      id: 'default_1',
      name: 'Classic Alarm',
      assetPath: 'assets/sounds/classic_alarm.mp3',
      isDefault: true,
    ),
    AlarmSound(
      id: 'default_2',
      name: 'Gentle Wake',
      assetPath: 'assets/sounds/gentle_wake.mp3',
      isDefault: true,
    ),
    AlarmSound(
      id: 'default_3',
      name: 'Beep Beep',
      assetPath: 'assets/sounds/beep_beep.mp3',
      isDefault: true,
    ),
    AlarmSound(
      id: 'default_4',
      name: 'Chime',
      assetPath: 'assets/sounds/chime.mp3',
      isDefault: true,
    ),
    AlarmSound(
      id: 'default_5',
      name: 'Bell',
      assetPath: 'assets/sounds/bell.mp3',
      isDefault: true,
    ),
  ];

  /// Get all default sounds
  List<AlarmSound> getDefaultSounds() => List.unmodifiable(_defaultSounds);

  /// Get all available sounds (default + custom)
  /// Note: Default sounds are always returned even if files don't exist
  /// The app will handle missing files gracefully when trying to play them
  Future<List<AlarmSound>> getAllSounds() async {
    final customSounds = await getCustomSounds();
    return [..._defaultSounds, ...customSounds];
  }

  /// Get custom sounds from device storage
  Future<List<AlarmSound>> getCustomSounds() async {
    if (kIsWeb) {
      // On web, return session-only list to avoid quota exceptions
      return List.unmodifiable(_webCustomList);
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final soundsDir = Directory(path.join(appDir.path, 'alarm_sounds'));
      
      if (!await soundsDir.exists()) {
        return [];
      }

      final files = soundsDir.listSync();
      final customSounds = <AlarmSound>[];

      for (var file in files) {
        if (file is File) {
          final ext = path.extension(file.path).toLowerCase();
          if (ext == '.mp3' || ext == '.wav' || ext == '.m4a') {
            final fileName = path.basenameWithoutExtension(file.path);
            customSounds.add(
              AlarmSound(
                id: 'custom_${path.basename(file.path)}',
                name: fileName,
                filePath: file.path,
                isDefault: false,
              ),
            );
          }
        }
      }

      return customSounds;
    } catch (e) {
      debugPrint('Error loading custom sounds: $e');
      return [];
    }
  }

  /// Save a custom sound file (for mobile/desktop)
  Future<AlarmSound?> saveCustomSound(File sourceFile, String name) async {
    if (kIsWeb) {
      debugPrint('Use saveCustomSoundFromBytes for web platform');
      return null;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final soundsDir = Directory(path.join(appDir.path, 'alarm_sounds'));
      
      if (!await soundsDir.exists()) {
        await soundsDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(sourceFile.path)}';
      final destFile = File(path.join(soundsDir.path, fileName));
      await sourceFile.copy(destFile.path);

      return AlarmSound(
        id: 'custom_$fileName',
        name: name,
        filePath: destFile.path,
        isDefault: false,
      );
    } catch (e) {
      debugPrint('Error saving custom sound: $e');
      return null;
    }
  }

  /// Save a custom sound from bytes (for web)
  Future<AlarmSound?> saveCustomSoundFromBytes(
    Uint8List bytes,
    String name,
    String originalFileName,
  ) async {
    if (!kIsWeb) {
      debugPrint('Use saveCustomSound for mobile/desktop platform');
      return null;
    }

    try {
      // Limit size to ~3MB to avoid browser memory limits
      if (bytes.length > 3 * 1024 * 1024) {
        debugPrint('Custom sound too large (>3MB), rejecting to avoid browser limits');
        return null;
      }
      final base64String = base64Encode(bytes);
      final soundId = 'custom_web_${DateTime.now().millisecondsSinceEpoch}_$originalFileName';
      _webSoundCache[soundId] = base64String;
      final sound = AlarmSound(
        id: soundId,
        name: name,
        filePath: soundId, // identifier for web cache
        isDefault: false,
      );
      _webCustomList.add(sound);

      return sound;
    } catch (e) {
      debugPrint('Error saving custom sound from bytes: $e');
      return null;
    }
  }

  /// Delete a custom sound
  Future<bool> deleteCustomSound(AlarmSound sound) async {
    if (sound.isDefault) {
      return false;
    }

    try {
      if (kIsWeb && sound.filePath != null && sound.filePath!.startsWith('custom_web_')) {
        _webSoundCache.remove(sound.filePath);
        _webCustomList.removeWhere((s) => s.id == sound.id);
        return true;
      } else if (!kIsWeb && sound.filePath != null) {
        // Delete file on mobile/desktop
        final file = File(sound.filePath!);
        if (await file.exists()) {
          await file.delete();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting custom sound: $e');
      return false;
    }
  }

  /// Play a sound (for preview)
  Future<void> playSound(AlarmSound sound, {bool loop = false}) async {
    try {
      if (sound.assetPath != null) {
        // Play from assets - AssetSource expects path without 'assets/' prefix
        final assetPath = sound.assetPath!.replaceFirst('assets/', '');
        try {
          await _audioPlayer.play(AssetSource(assetPath));
        } catch (e) {
          debugPrint('Error playing asset sound $assetPath: $e');
          debugPrint('Note: Make sure the sound file exists in assets/sounds/');
          rethrow;
        }
      } else if (sound.filePath != null) {
        if (kIsWeb && sound.filePath!.startsWith('custom_web_')) {
          // On web, load from in-memory cache and create data URL
          final base64String = _webSoundCache[sound.filePath!];
          if (base64String != null) {
            final extension = path.extension(sound.filePath!).toLowerCase();
            final mimeType = extension == '.mp3'
                ? 'audio/mpeg'
                : extension == '.wav'
                    ? 'audio/wav'
                    : extension == '.m4a'
                        ? 'audio/mp4'
                        : 'audio/mpeg';
            final dataUrl = 'data:$mimeType;base64,$base64String';
            try {
              await _audioPlayer.play(UrlSource(dataUrl));
            } catch (e) {
              debugPrint('Error playing web custom sound: $e');
              rethrow;
            }
          } else {
            debugPrint('Sound data not available (session only on web): ${sound.filePath}');
            throw Exception('Sound data not available (session only on web)');
          }
        } else if (!kIsWeb) {
          // Play from file system (mobile/desktop)
          final file = File(sound.filePath!);
          if (await file.exists()) {
            await _audioPlayer.play(DeviceFileSource(sound.filePath!));
          } else {
            debugPrint('Sound file not found: ${sound.filePath}');
            return;
          }
        } else {
          debugPrint('Cannot play sound: invalid path for platform');
          return;
        }
      } else {
        debugPrint('Cannot play sound: no valid path available');
        return;
      }

      if (loop) {
        _audioPlayer.setReleaseMode(ReleaseMode.loop);
      } else {
        _audioPlayer.setReleaseMode(ReleaseMode.release);
      }
    } catch (e) {
      debugPrint('Error playing sound: $e');
      // Re-throw to let UI handle the error
      rethrow;
    }
  }

  /// Stop playing sound
  Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping sound: $e');
    }
  }

  /// Play sound for alarm (used by AlarmService)
  Future<void> playAlarmSound(AlarmSound sound) async {
    try {
      if (sound.assetPath != null) {
        final assetPath = sound.assetPath!.replaceFirst('assets/', '');
        try {
          await _audioPlayer.play(AssetSource(assetPath), mode: PlayerMode.lowLatency);
        } catch (e) {
          debugPrint('Error playing alarm asset sound $assetPath: $e');
          debugPrint('Note: Make sure the sound file exists in assets/sounds/');
          // Don't rethrow - just log, as alarm should still work without sound
          return;
        }
      } else if (sound.filePath != null) {
        if (kIsWeb && sound.filePath!.startsWith('custom_web_')) {
          // On web, load from in-memory cache and create data URL
          try {
            final base64String = _webSoundCache[sound.filePath!];
            if (base64String != null) {
              final extension = path.extension(sound.filePath!).toLowerCase();
              final mimeType = extension == '.mp3'
                  ? 'audio/mpeg'
                  : extension == '.wav'
                      ? 'audio/wav'
                      : extension == '.m4a'
                          ? 'audio/mp4'
                          : 'audio/mpeg';
              final dataUrl = 'data:$mimeType;base64,$base64String';
              await _audioPlayer.play(UrlSource(dataUrl), mode: PlayerMode.lowLatency);
            } else {
              debugPrint('Alarm sound data not available (session only on web): ${sound.filePath}');
              return;
            }
          } catch (e) {
            debugPrint('Error playing web custom alarm sound: $e');
            return;
          }
        } else if (!kIsWeb) {
          // Play from file system (mobile/desktop)
          final file = File(sound.filePath!);
          if (await file.exists()) {
            await _audioPlayer.play(DeviceFileSource(sound.filePath!), mode: PlayerMode.lowLatency);
          } else {
            debugPrint('Alarm sound file not found: ${sound.filePath}');
            return;
          }
        } else {
          debugPrint('Cannot play alarm sound: invalid path for platform');
          return;
        }
      } else {
        debugPrint('Cannot play alarm sound: no valid path available');
        return;
      }
      
      // Loop the alarm sound
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      debugPrint('Error playing alarm sound: $e');
    }
  }

  /// Stop alarm sound
  Future<void> stopAlarmSound() async {
    try {
      await _audioPlayer.stop();
      _audioPlayer.setReleaseMode(ReleaseMode.release);
    } catch (e) {
      debugPrint('Error stopping alarm sound: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}


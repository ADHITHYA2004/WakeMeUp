import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import '../models/destination.dart';
import '../models/alarm_sound.dart';
import '../services/alarm_service.dart';
import '../services/sound_service.dart';

/// Screen to set alarm distance and start tracking
class SetAlarmScreen extends StatefulWidget {
  const SetAlarmScreen({super.key});

  @override
  State<SetAlarmScreen> createState() => _SetAlarmScreenState();
}

class _SetAlarmScreenState extends State<SetAlarmScreen> {
  double _selectedDistance = 1000.0; // Default 1km in meters
  Destination? _destination;
  AlarmSound? _selectedSound;
  List<AlarmSound> _availableSounds = [];
  bool _isLoadingSounds = true;
  AlarmSound? _previewingSound;

  // Available distance options
  final List<Map<String, dynamic>> _distanceOptions = [
    {'value': 500.0, 'label': '500 meters', 'display': '500m'},
    {'value': 1000.0, 'label': '1 kilometer', 'display': '1km'},
    {'value': 2000.0, 'label': '2 kilometers', 'display': '2km'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSounds();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get destination from route arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Destination) {
      _destination = args;
    }
  }

  /// Load available sounds
  Future<void> _loadSounds() async {
    setState(() {
      _isLoadingSounds = true;
    });

    try {
      final sounds = await SoundService.instance.getAllSounds();
      setState(() {
        _availableSounds = sounds;
        // Set first default sound as default selection
        if (_selectedSound == null && sounds.isNotEmpty) {
          _selectedSound = sounds.firstWhere(
            (s) => s.isDefault,
            orElse: () => sounds.first,
          );
        }
        _isLoadingSounds = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSounds = false;
      });
    }
  }

  /// Pick a custom sound file
  Future<void> _pickCustomSound() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.name.isNotEmpty) {
        final pickedFile = result.files.single;
        final fileName = pickedFile.name;

        // Show dialog to name the sound
        final nameController = TextEditingController(
          text: fileName.split('.').first,
        );

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text('Name Your Sound'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Sound Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          ),
        );

        if (confirmed == true && nameController.text.isNotEmpty) {
          AlarmSound? savedSound;
          
          if (kIsWeb) {
            // On web, use bytes instead of file path
            if (pickedFile.bytes != null) {
              savedSound = await SoundService.instance.saveCustomSoundFromBytes(
                pickedFile.bytes!,
                nameController.text,
                fileName,
              );
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to read file bytes'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }
          } else {
            // On mobile/desktop, use file path
            if (pickedFile.path != null) {
              final file = File(pickedFile.path!);
              savedSound = await SoundService.instance.saveCustomSound(
                file,
                nameController.text,
              );
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('File path not available'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }
          }

          if (savedSound != null) {
            setState(() {
              _availableSounds.add(savedSound!);
              _selectedSound = savedSound;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Custom sound added!')),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to save custom sound')),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Preview a sound
  Future<void> _previewSound(AlarmSound sound) async {
    // Stop current preview
    if (_previewingSound != null) {
      await SoundService.instance.stopSound();
    }

    setState(() {
      _previewingSound = sound;
    });

    try {
      await SoundService.instance.playSound(sound, loop: false);
      
      // Reset preview state after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _previewingSound == sound) {
          setState(() {
            _previewingSound = null;
          });
        }
      });
    } catch (e) {
      // Handle error gracefully
      setState(() {
        _previewingSound = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sound.isDefault
                  ? 'Sound file not found. Please add ${sound.name.toLowerCase()} to assets/sounds/'
                  : 'Error playing sound: $e',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Start the alarm tracking
  Future<void> _startTracking() async {
    if (_destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No destination selected')),
      );
      return;
    }

    // Start alarm service
    await AlarmService.instance.startAlarm(
      _destination!,
      _selectedDistance,
      (alarmState) {
        // This callback will be handled in ActiveAlarmScreen
      },
      alarmSound: _selectedSound,
    );

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/active-alarm',
        arguments: {
          'destination': _destination,
          'alertDistance': _selectedDistance,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_destination == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Set Alarm')),
        body: const Center(child: Text('No destination selected')),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Alarm'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Destination info card with modern design
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: colorScheme.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Destination',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _destination!.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Distance selector title
                Text(
                  'Alert Distance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                // Modern segmented distance selector
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: _distanceOptions.map((option) {
                      final isSelected =
                          option['value'] == _selectedDistance;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDistance = option['value'] as double;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  option['display'] as String,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  option['label']
                                      .toString()
                                      .replaceAll('1 kilometer', '1 km')
                                      .replaceAll('2 kilometers', '2 km')
                                      .replaceAll('500 meters', '500 m'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.white.withOpacity(0.8)
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),
                // Alarm Sound selector title
                Text(
                  'Alarm Sound',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                // Sound selection card
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isLoadingSounds
                      ? const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Column(
                          children: [
                            // Default sounds section
                            if (_availableSounds.where((s) => s.isDefault).isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.music_note_rounded,
                                      color: colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Default Sounds',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              // Info banner if no sound files exist
                              if (_availableSounds.where((s) => s.isDefault).isEmpty ||
                                  _availableSounds.where((s) => s.isDefault).length < 5)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.orange.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          color: Colors.orange.shade700,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Default sound files not found. Add custom sounds or place audio files in assets/sounds/',
                                            style: TextStyle(
                                              color: Colors.orange.shade700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ..._availableSounds
                                  .where((s) => s.isDefault)
                                  .map((sound) => _buildSoundTile(sound)),
                            ],
                            // Custom sounds section
                            if (_availableSounds.where((s) => s.isCustom).isNotEmpty) ...[
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.audio_file_rounded,
                                      color: colorScheme.secondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Custom Sounds',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              ..._availableSounds
                                  .where((s) => s.isCustom)
                                  .map((sound) => _buildSoundTile(sound)),
                            ],
                            // Add custom sound button
                            const Divider(height: 1),
                            ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: colorScheme.secondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.add_rounded,
                                  color: colorScheme.secondary,
                                ),
                              ),
                              title: Text(
                                'Add Custom Sound',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              subtitle: const Text('Pick an audio file from your device'),
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey[400],
                              ),
                              onTap: _pickCustomSound,
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 32),
                // Info card with modern design
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'You will be alerted when you are ${_distanceOptions.firstWhere((opt) => opt['value'] == _selectedDistance)['display']} away from your destination.',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Start tracking button with modern design
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _startTracking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
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
                        Icon(Icons.play_arrow_rounded, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Start Tracking',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build a sound selection tile
  Widget _buildSoundTile(AlarmSound sound) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedSound?.id == sound.id;
    final isPreviewing = _previewingSound?.id == sound.id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSound = sound;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Selection indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected
                    ? colorScheme.primary
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Sound icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (sound.isDefault
                        ? colorScheme.primary
                        : colorScheme.secondary)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                sound.isDefault
                    ? Icons.music_note_rounded
                    : Icons.audio_file_rounded,
                color: sound.isDefault
                    ? colorScheme.primary
                    : colorScheme.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Sound name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sound.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? colorScheme.primary
                              : null,
                        ),
                  ),
                  if (sound.isCustom)
                    Text(
                      'Custom',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                ],
              ),
            ),
            // Preview button
            IconButton(
              icon: Icon(
                isPreviewing
                    ? Icons.stop_circle_rounded
                    : Icons.play_circle_outline_rounded,
                color: isPreviewing
                    ? Colors.red
                    : colorScheme.primary,
              ),
              onPressed: () {
                if (isPreviewing) {
                  SoundService.instance.stopSound();
                  setState(() {
                    _previewingSound = null;
                  });
                } else {
                  _previewSound(sound);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}


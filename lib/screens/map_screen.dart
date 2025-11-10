import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/destination.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';

/// Map screen to select destination and show current position
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  LatLng? _selectedDestination;
  String? _destinationName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentPosition();
  }

  /// Load current GPS position
  Future<void> _loadCurrentPosition() async {
    final position = await LocationService.instance.getCurrentPosition();
    if (position != null) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      try {
        _mapController.move(_currentPosition!, 15);
      } catch (_) {}
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get current location. Please enable location services.'),
          ),
        );
      }
    }
  }

  /// Handle map tap to select destination
  void _onMapTap(TapPosition _, LatLng position) {
    setState(() {
      _selectedDestination = position;
    });
    _showDestinationNameDialog();
  }

  /// Show dialog to enter destination name
  Future<void> _showDestinationNameDialog() async {
    final TextEditingController nameController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              'Destination Name',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            // Text field
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Enter destination name',
                prefixIcon: Icon(
                  Icons.edit_location_rounded,
                  color: colorScheme.primary,
                ),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 32),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isNotEmpty) {
                        Navigator.pop(context, nameController.text);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded),
                        SizedBox(width: 8),
                        Text('Save'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (result != null && _selectedDestination != null) {
      setState(() {
        _destinationName = result;
      });
      _saveAndNavigate();
    }
  }

  /// Save destination and navigate to set alarm screen
  Future<void> _saveAndNavigate() async {
    if (_selectedDestination == null || _destinationName == null) return;

    final destination = Destination(
      name: _destinationName!,
      latitude: _selectedDestination!.latitude,
      longitude: _selectedDestination!.longitude,
    );

    // Save to database
    await DatabaseService.instance.insertDestination(destination);

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/set-alarm',
        arguments: destination,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Select Destination'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Check if we have a valid position, if not show error
    if (_currentPosition == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Select Destination'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 24),
                Text(
                  'Unable to load map',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please ensure location services are enabled.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Destination'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentPosition != null) {
            _mapController.move(_currentPosition!, 15);
          }
        },
        child: const Icon(Icons.gps_fixed),
      ),
      body: Stack(
        children: [
          // FlutterMap view (OpenStreetMap)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition!,
              initialZoom: 15,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.wakemeup_travel_alarm',
                maxZoom: 19,
              ),
              if (_selectedDestination != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _selectedDestination!,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                      borderStrokeWidth: 2,
                      borderColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      useRadiusInMeter: true,
                      radius: 500,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                    ),
                  if (_selectedDestination != null)
                    Marker(
                      point: _selectedDestination!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.place, color: Colors.red, size: 34),
                    ),
                ],
              ),
            ],
          ),
          // Instructions overlay with modern design
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.touch_app_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Tap on the map to select your destination',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // MapController from flutter_map does not require dispose.
    super.dispose();
  }
}


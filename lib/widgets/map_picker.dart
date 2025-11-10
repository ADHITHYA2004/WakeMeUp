import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Reusable widget for picking a location on the map
/// This component can be used across different screens
class MapPicker extends StatefulWidget {
  final LatLng? initialPosition;
  final Function(LatLng) onLocationSelected;
  final String? selectedLocationName;

  const MapPicker({
    super.key,
    this.initialPosition,
    required this.onLocationSelected,
    this.selectedLocationName,
  });

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.initialPosition ?? const LatLng(0, 0),
            zoom: 15,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
          },
          onTap: (location) {
            setState(() {
              _selectedLocation = location;
            });
            widget.onLocationSelected(location);
          },
          markers: widget.selectedLocationName != null && _selectedLocation != null
              ? {
                  Marker(
                    markerId: const MarkerId('selected'),
                    position: _selectedLocation!,
                    infoWindow: InfoWindow(
                      title: widget.selectedLocationName!,
                    ),
                  ),
                }
              : {},
        ),
        // Instructions overlay
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Icon(Icons.touch_app),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap to select location',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}


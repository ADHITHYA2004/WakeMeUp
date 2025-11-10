# WakeMeUp Travel Alarm

A Flutter mobile app that wakes up passengers before they reach their destination using GPS-based distance alerts.

## Features

- 🗺️ Interactive map to select destination (Google Maps)
- 📍 Real-time GPS tracking with high accuracy
- 🔔 Distance-based alarm alerts (500m, 1km, 2km)
- 🌙 Dark mode support with theme persistence
- 💾 Local storage for destination history (SQLite)
- 📱 Background location tracking
- 🔊 Sound and vibration alerts
- 🎨 Modern UI with gradient backgrounds and rounded cards
- 📱 Cross-platform (Android & iOS)

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   ├── destination.dart      # Destination data model
│   └── alarm_state.dart      # Alarm state model
├── screens/
│   ├── home_screen.dart      # Welcome/home screen
│   ├── map_screen.dart       # Map for destination selection
│   ├── set_alarm_screen.dart # Configure alarm distance
│   ├── active_alarm_screen.dart # Live tracking screen
│   └── settings_screen.dart  # Settings & destination history
├── services/
│   ├── alarm_service.dart    # Alarm logic & notifications
│   ├── location_service.dart # GPS tracking service
│   ├── database_service.dart # SQLite database operations
│   └── theme_service.dart    # Theme management
└── widgets/
    ├── map_picker.dart       # Reusable map picker component
    └── alarm_controller.dart # Reusable alarm controller
```

## Setup

See [SETUP.md](SETUP.md) for detailed setup instructions.

### Quick Start

1. **Install dependencies:**

```bash
flutter pub get
```

2. **Configure Google Maps API Key:**

   - Get API key from [Google Cloud Console](https://console.cloud.google.com/)
   - Android: Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` in `android/app/src/main/AndroidManifest.xml`
   - iOS: Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` in `ios/Runner/AppDelegate.swift` and `ios/Runner/Info.plist`

3. **Run the app:**

```bash
flutter run
```

## Usage

1. **Set Destination**: Tap "Set Destination" on home screen, then tap on the map to select your destination
2. **Configure Alarm**: Choose alert distance (500m, 1km, or 2km) and tap "Start Tracking"
3. **Monitor**: Watch live distance updates on the Active Alarm screen
4. **Alert**: When within the alert distance, the app will trigger sound, vibration, and notification

## Tech Stack

- **Framework**: Flutter (Dart 3.0+)
- **Maps**: Google Maps Flutter Plugin
- **Location**: Geolocator (Haversine formula for distance calculation)
- **Storage**: SQLite (sqflite)
- **Notifications**: Flutter Local Notifications
- **State Management**: Provider
- **UI**: Material Design 3 with Google Fonts (Poppins)

## Permissions Required

- **Location (Foreground & Background)**: For GPS tracking
- **Vibration**: For alarm alerts
- **Notifications**: For alarm notifications

## Notes

- The app uses high-accuracy GPS which may impact battery life
- Background location tracking requires appropriate permissions
- Google Maps API has usage limits (free tier available)
- For production, consider implementing battery optimization strategies

## License

This project is open source and available for personal use.

# Setup Instructions for WakeMeUp Travel Alarm

## Prerequisites

1. **Flutter SDK**: Install Flutter (version 3.0.0 or higher)

   - Download from: https://flutter.dev/docs/get-started/install
   - Verify installation: `flutter doctor`

2. **Google Maps API Key**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select existing one
   - Enable the following APIs:
     - "Maps SDK for Android" (for Android)
     - "Maps SDK for iOS" (for iOS)
     - "Maps JavaScript API" (for Web) ⚠️ **Required for web platform**
   - Create an API key
   - Restrict the key to your app's package name for security

## Installation Steps

### 1. Install Dependencies

```bash
cd /Users/macos/Desktop/WakeMeUp
flutter pub get
```

### 2. Configure Google Maps API Key

#### Android:

1. Open `android/app/src/main/AndroidManifest.xml`
2. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key

#### iOS:

1. Open `ios/Runner/Info.plist`
2. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key
3. Also add the key to `ios/Runner/AppDelegate.swift` if needed:

#### Web:

1. Open `web/index.html`
2. Find the line with `YOUR_GOOGLE_MAPS_API_KEY_HERE` in the Google Maps script tag
3. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key
4. **Important**: Make sure "Maps JavaScript API" is enabled in Google Cloud Console

```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 3. Configure Permissions

#### Android:

- Permissions are already configured in `AndroidManifest.xml`
- For background location on Android 10+, you may need to request additional permissions at runtime

#### iOS:

- Permissions are configured in `Info.plist`
- The app will request permissions when first accessing location

### 4. Run the App

```bash
# For Android
flutter run

# For iOS (requires macOS and Xcode)
flutter run

# For a specific device
flutter devices  # List available devices
flutter run -d <device-id>
```

## Testing

1. **Test Location Services**:

   - Grant location permissions when prompted
   - Verify current location appears on map

2. **Test Alarm**:

   - Select a destination on the map
   - Set alert distance (500m, 1km, or 2km)
   - Start tracking
   - Move within the alert distance to trigger alarm

3. **Test Background Tracking**:
   - Start an alarm
   - Minimize the app
   - The alarm should still trigger when within range

## Troubleshooting

### Maps not showing:

- Verify Google Maps API key is correctly set
- Check that Maps SDK is enabled in Google Cloud Console
- Ensure internet connection is available

### Location not working:

- Check device location services are enabled
- Grant location permissions in device settings
- For Android: Ensure location permission is granted in app settings

### Alarm not triggering:

- Verify location permissions include background location
- Check that device location services are enabled
- Ensure app has necessary battery optimization exemptions

### Build errors:

- Run `flutter clean` and `flutter pub get`
- Ensure all dependencies are compatible
- Check Flutter version: `flutter --version`

## Notes

- The app uses high-accuracy GPS which may drain battery faster
- Background location tracking requires appropriate permissions
- Google Maps API has usage limits (free tier available)
- For production, consider implementing battery optimization strategies

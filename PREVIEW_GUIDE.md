# How to Preview WakeMeUp Travel Alarm App

## Option 1: Run on Emulator/Simulator (Recommended)

### Prerequisites:

1. **Install Flutter**:

   ```bash
   # Download Flutter SDK from https://flutter.dev/docs/get-started/install/macos
   # Extract and add to PATH, or use Homebrew:
   brew install --cask flutter
   ```

2. **Verify Installation**:

   ```bash
   flutter doctor
   ```

3. **Install Dependencies**:
   ```bash
   cd /Users/macos/Desktop/WakeMeUp
   flutter pub get
   ```

### For Android Preview:

1. **Install Android Studio** (if not already installed)
2. **Set up Android Emulator**:

   - Open Android Studio
   - Go to Tools > Device Manager
   - Create a new virtual device (e.g., Pixel 5)
   - Start the emulator

3. **Run the App**:
   ```bash
   flutter run
   ```

### For iOS Preview (macOS only):

1. **Install Xcode** from App Store
2. **Install CocoaPods**:

   ```bash
   sudo gem install cocoapods
   cd ios && pod install && cd ..
   ```

3. **Run the App**:
   ```bash
   flutter run
   ```

## Option 2: Run on Physical Device

### Android Device:

1. Enable **Developer Options** and **USB Debugging** on your Android phone
2. Connect via USB
3. Run: `flutter run`

### iOS Device:

1. Connect iPhone via USB
2. Trust the computer on your iPhone
3. Run: `flutter run`

## Option 3: Quick Preview (Without Full Setup)

If you just want to see the UI structure without running the full app, you can:

1. **View the code structure** - All screens are in `lib/screens/`
2. **Check the UI components** - See `lib/widgets/` for reusable components
3. **Review screenshots/design** - The app uses Material Design 3 with:
   - Gradient backgrounds (blue to teal)
   - Rounded cards
   - Modern typography (Poppins font)

## Quick Start Commands

```bash
# Navigate to project
cd /Users/macos/Desktop/WakeMeUp

# Install dependencies
flutter pub get

# Check available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Run in debug mode with hot reload
flutter run --debug

# Build APK for Android (for testing)
flutter build apk --debug
```

## Troubleshooting

### "Flutter command not found":

- Add Flutter to your PATH:
  ```bash
  export PATH="$PATH:/path/to/flutter/bin"
  ```
- Or use full path: `/path/to/flutter/bin/flutter run`

### "No devices found":

- For Android: Start an emulator or connect a device
- For iOS: Open Simulator from Xcode or connect iPhone

### Maps not showing:

- You need to add Google Maps API key (see SETUP.md)
- Maps will show blank/error without API key, but other screens will work

### Permission errors:

- Grant location permissions when prompted
- Check device settings if permissions are denied

## Preview Screens Flow

1. **Home Screen**: Welcome with "Set Destination" button
2. **Map Screen**: Tap to select destination
3. **Set Alarm Screen**: Choose distance (500m/1km/2km)
4. **Active Alarm Screen**: Live distance tracking
5. **Settings Screen**: Dark mode toggle & destination history

## Note

For a full preview with all features working:

- Google Maps API key is required (free tier available)
- Location permissions must be granted
- Device/emulator must support location services


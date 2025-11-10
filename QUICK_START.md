# Quick Start - Preview the App

## Step 1: Install Flutter (5-10 minutes)

### On macOS:

**Option A: Using Homebrew (Easiest)**

```bash
brew install --cask flutter
```

**Option B: Manual Installation**

1. Download Flutter SDK from: https://docs.flutter.dev/get-started/install/macos
2. Extract the zip file
3. Add Flutter to your PATH:
   ```bash
   export PATH="$PATH:/path/to/flutter/bin"
   ```
   Add this line to `~/.zshrc` to make it permanent

**Verify Installation:**

```bash
flutter doctor
```

## Step 2: Set Up an Emulator/Simulator

### For Android:

1. Install Android Studio: https://developer.android.com/studio
2. Open Android Studio → Tools → Device Manager
3. Click "Create Device" → Choose Pixel 5 or similar
4. Click "Start" to launch emulator

### For iOS (macOS only):

1. Install Xcode from App Store
2. Open Xcode → Preferences → Components
3. Install iOS Simulator
4. Or run: `open -a Simulator`

## Step 3: Run the App

```bash
# Navigate to project
cd /Users/macos/Desktop/WakeMeUp

# Install dependencies
flutter pub get

# Check available devices
flutter devices

# Run the app
flutter run
```

## What You'll See:

1. **Home Screen**:

   - Blue-to-teal gradient background
   - Large location icon animation
   - "WakeMeUp Travel Alarm" title
   - "Set Destination" button

2. **Map Screen** (after tapping Set Destination):

   - Google Maps view
   - Your current location (blue marker)
   - Tap anywhere to set destination (red marker)

3. **Set Alarm Screen**:

   - Destination name card
   - Distance selector dropdown (500m/1km/2km)
   - "Start Tracking" button

4. **Active Alarm Screen**:

   - Live distance counter
   - Animated alarm icon
   - "Cancel Alarm" button

5. **Settings Screen**:
   - Dark mode toggle
   - Destination history list

## Troubleshooting

**"flutter: command not found"**

- Make sure Flutter is in your PATH
- Restart terminal after installation
- Try: `which flutter` to verify

**"No devices found"**

- Start an Android emulator or iOS simulator first
- Or connect a physical device via USB

**Maps show blank/error**

- This is normal without Google Maps API key
- Other screens will still work
- See SETUP.md to add API key

## Alternative: View Code Structure

If you can't run Flutter right now, you can explore the UI code:

- **Home Screen**: `lib/screens/home_screen.dart`
- **Map Screen**: `lib/screens/map_screen.dart`
- **Set Alarm**: `lib/screens/set_alarm_screen.dart`
- **Active Alarm**: `lib/screens/active_alarm_screen.dart`
- **Settings**: `lib/screens/settings_screen.dart`

Each file has detailed comments explaining the UI components!

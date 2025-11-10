#!/bin/bash

# WakeMeUp Travel Alarm - Installation and Run Script

echo "🚀 WakeMeUp Travel Alarm - Setup Script"
echo "========================================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed!"
    echo ""
    echo "📦 Installing Flutter..."
    echo ""
    echo "Option 1: Using Homebrew (Recommended)"
    echo "  Run: brew install --cask flutter"
    echo ""
    echo "Option 2: Manual Installation"
    echo "  1. Visit: https://docs.flutter.dev/get-started/install/macos"
    echo "  2. Download and extract Flutter SDK"
    echo "  3. Add to PATH: export PATH=\"\$PATH:/path/to/flutter/bin\""
    echo ""
    echo "After installing Flutter, run this script again."
    exit 1
fi

echo "✅ Flutter is installed!"
echo ""

# Check Flutter version
echo "📋 Flutter Version:"
flutter --version | head -1
echo ""

# Navigate to project directory
cd "$(dirname "$0")"

# Install dependencies
echo "📦 Installing dependencies..."
flutter pub get
echo ""

# Check for devices
echo "📱 Checking for available devices..."
flutter devices
echo ""

# Ask user what to do
echo "What would you like to do?"
echo "1. Run the app (flutter run)"
echo "2. Check Flutter setup (flutter doctor)"
echo "3. List available devices"
echo ""
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        echo ""
        echo "🚀 Starting the app..."
        flutter run
        ;;
    2)
        echo ""
        echo "🔍 Checking Flutter setup..."
        flutter doctor
        ;;
    3)
        echo ""
        echo "📱 Available devices:"
        flutter devices
        ;;
    *)
        echo "Invalid choice"
        ;;
esac


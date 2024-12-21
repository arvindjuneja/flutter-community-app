#!/bin/bash
set -e
echo "Downloading Flutter SDK..."
FLUTTER_VERSION=${FLUTTER_VERSION:-"3.27.1"}
git clone -b $FLUTTER_VERSION https://github.com/flutter/flutter.git
echo "Adding Flutter to PATH..."
export PATH="$PWD/flutter/bin:$PATH"
echo "Enabling web support..."
flutter config --enable-web
flutter doctor -v
echo "Getting dependencies..."
flutter pub get
echo "Building web app..."
flutter build web --release